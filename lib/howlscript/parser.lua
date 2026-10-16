-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Parses the tokens from the lexer into an AST: a list of statement nodes.
--
-- Nodes are tables with `k` (the kind) and `line`/`col` (where they start).
--
-- Expressions:
--   Nil, True, False, Vararg, Self (@), ClassRef (@@), Super
--   Number{v}, Name{v}, SelfField{name} (@x), ClassField{name} (@@x)
--   String{q, parts}: parts are text (ready for Lua, inside quote q) or expressions
--   WithField{name} (.x in a with block), WithCall{name, args} (:x() in a with block)
--   Field{obj, name}, Index{obj, key}, Slice{obj, start, stop, step}
--   Call{fn, args}, MethodCall{obj, name, args}
--   Unop{op, e}, Binop{op, l, r}, Paren{e}
--   Table{entries, implicit}: entries are {k = 'pos', v}, {k = 'named', key, v} or
--     {k = 'expr', key, v}, where `key` is a string or, for 'expr', an expression
--   Func{params, body, fat}: params are {name, tok, default, self_assign, pattern,
--     vararg}
--   Comprehension{kind = 'list', expr, clauses} or {kind = 'table', kexpr, vexpr,
--     clauses}: clauses are a For or ForIn node without a body, optionally followed
--     by {k = 'filter', cond, unless} for `if cond` or `unless cond`
--   Raw{code}: Lua code, only created by the compiler
--
-- Statements (With can also be a value):
--   Assign{targets, values}, Update{target, op, value}, ExprStmt{exprs}
--   Return{values}, Break, Continue
--   Local{names, values}, Export{names, values} / {all} / {class}
--   If{conds, bodies, else_body, unless, decorator}
--   Switch{subject, clauses = {{values, body, line}}, else_body}
--   With{target, body}, Do{body}, While{cond, body}
--   For{var, var_tok, start, stop, step, body}
--   ForIn{vars, exprs, body} or {vars, star, body} for `in *t`
--   Class{name, parent, body}: the body holds statements and the items
--     {k = 'prop', key, value} and {k = 'classvar', key, value}
--
-- Assignment targets and loop variables can be Pattern{entries} for destructuring,
-- with entries like a Table's, holding a `target` instead of `v`.
--
-- Whether a line break ends an expression depends on the innermost context on
-- `self.ctx`: in a 'block', a 'header' (the head of an if, for, ...) or the 'bare'
-- arguments of a call without parentheses it ends the statement, in 'call'
-- arguments and 'table's it separates entries, and in a 'group' (parentheses), an
-- 'index' or a 'compr'ehension it's just whitespace. An 'inline' context marks an
-- inline body inside call arguments or a table, and otherwise defers to the
-- context around it.
--
-- A call can leave out its parentheses only when it's a statement directly in a
-- block, and only one level deep: calls in its arguments, and calls inside
-- brackets, need them. `bare_at` is the index of the token where such a call can
-- start.

-- The JIT only slows code this recursive and branchy down: it keeps recording
-- traces that abort, which made compiling several times slower.
jit.off(true, true)

local raise = require('howlscript.errors').raise

local Parser = {}
Parser.__index = Parser

-- left and right priorities, as in Lua's own parser
local binops = {
  ['or'] = { 1, 1 }, ['and'] = { 2, 2 },
  ['<'] = { 3, 3 }, ['>'] = { 3, 3 }, ['<='] = { 3, 3 }, ['>='] = { 3, 3 },
  ['=='] = { 3, 3 }, ['!='] = { 3, 3 }, ['~='] = { 3, 3 },
  ['..'] = { 5, 4 },
  ['+'] = { 6, 6 }, ['-'] = { 6, 6 },
  ['*'] = { 7, 7 }, ['/'] = { 7, 7 }, ['%'] = { 7, 7 },
  ['^'] = { 10, 9 },
}
local UNARY_PRIORITY = 8

local update_ops = {
  ['+='] = '+', ['-='] = '-', ['*='] = '*', ['/='] = '/', ['%='] = '%',
  ['..='] = '..', ['or='] = 'or', ['and='] = 'and',
}

local assignable = {
  Name = true, Field = true, Index = true, SelfField = true, ClassField = true,
  WithField = true,
}

local function is_op(t, v) return t.t == 'op' and t.v == v end
local function is_kw(t, v) return t.t == 'keyword' and t.v == v end
local function is_name_like(t) return t.t == 'name' or t.t == 'keyword' end

local function is_closer(t)
  return t.t == 'op' and (t.v == ')' or t.v == ']' or t.v == '}')
end

local function node(k, at, fields)
  local n = fields or {}
  n.k = k
  n.line = at.line
  n.col = at.col
  return n
end

local function describe(t)
  if t.t == 'eof' then return 'end of input' end
  if t.t == 'string' then return 'a string' end
  return "'" .. t.v .. "'"
end

local function new_parser(tokens, with_depth)
  return setmetatable({
    toks = tokens,
    i = 1,
    t = tokens[1],
    ctx = {},
    ref = -1,
    with_depth = with_depth or 0,
  }, Parser)
end

-- Token handling

function Parser:advance()
  local t = self.t
  if t.t ~= 'eof' then
    self.i = self.i + 1
    self.t = self.toks[self.i]
  end
  return t
end

function Parser:peek(n)
  return self.toks[self.i + n] or self.toks[#self.toks]
end

function Parser:error(message, tok)
  tok = tok or self.t
  raise(message, tok.line, tok.col, tok.v and #tok.v or nil)
end

function Parser:accept_op(v)
  if is_op(self.t, v) then return self:advance() end
end

function Parser:expect_op(v)
  if not is_op(self.t, v) then
    self:error(string.format("expected '%s' near %s", v, describe(self.t)))
  end
  return self:advance()
end

function Parser:expect_closer(v, open)
  if not is_op(self.t, v) then
    self:error(string.format("expected '%s' to close the '%s' on line %d, near %s",
      v, open.v, open.line, describe(self.t)))
  end
  return self:advance()
end

-- The index of the token closing the bracket at index i.
function Parser:matching(i)
  local depth = 0
  local toks = self.toks
  for j = i, #toks do
    local t = toks[j]
    if t.t == 'op' then
      local v = t.v
      if v == '(' or v == '[' or v == '{' then
        depth = depth + 1
      elseif v == ')' or v == ']' or v == '}' then
        depth = depth - 1
        if depth == 0 then return j end
      end
    end
  end
end

-- Reports an unexpected token, with a hint when it looks like MoonScript habits.
function Parser:unexpected(t)
  t = t or self.t
  local prev = self.toks[self.i - 1]
  if is_op(t, '(') and t.sb and not t.first then
    self:error("no space is allowed between a function and the '(' of its call, as in f(x)", t)
  elseif is_op(t, '[') and t.sb and not t.first then
    self:error("no space is allowed before the '[' of an index, as in t[k]", t)
  elseif is_op(t, ':') and t.sa and prev and is_name_like(prev) then
    self:error("tables need braces, as in {key: value}; only a call's arguments can leave them out", t)
  elseif t.t == 'string' and t.q == '[' and not t.sb and prev and is_name_like(prev) then
    self:error('a long string touching a name is not a call; write f([[x]]), or f [[x]] as a statement', t)
  end
  self:error('unexpected ' .. describe(t), t)
end

-- Contexts

function Parser:push(kind, ctx)
  ctx = ctx or {}
  ctx.kind = kind
  self.ctx[#self.ctx + 1] = ctx
  return ctx
end

function Parser:pop()
  self.ctx[#self.ctx] = nil
end

-- The innermost context, apart from inline bodies.
function Parser:kind()
  local ctx = self.ctx
  local i = #ctx
  while ctx[i].kind == 'inline' do i = i - 1 end
  return ctx[i].kind
end

function Parser:in_inline()
  return self.ctx[#self.ctx].kind == 'inline'
end

-- Whether a closing bracket can end the current block: only inside brackets.
function Parser:in_bracket()
  for i = #self.ctx, 1, -1 do
    local k = self.ctx[i].kind
    if k ~= 'block' and k ~= 'header' and k ~= 'bare' and k ~= 'inline' then return true end
  end
  return false
end

-- True if the current token, at the start of a line, can't continue the expression
-- being parsed.
function Parser:ends_here()
  local t = self.t
  if t.t == 'eof' then return true end
  if not t.first then return false end
  local k = self:kind()
  return k ~= 'group' and k ~= 'index' and k ~= 'compr'
end

-- Whether expression lists can continue past a ','. Inside call arguments and
-- tables it separates the entries, except in an inline body there, which takes the
-- rest of the line's entries, as in MoonScript: `f(-> a, b)` passes a function
-- returning a and b. A ',' ending a line ends the body though, leaving the next line
-- to the arguments or the table.
function Parser:lists_allowed()
  if self:in_inline() then return not self:peek(1).first end
  local k = self:kind()
  return k == 'block' or k == 'header' or k == 'group'
end

-- After an operator, ',' or '=' ending a line the expression continues on the next
-- one, which in a block has to be indented deeper than the line it continues.
function Parser:continuation()
  local t = self.t
  if t.first then
    if t.t == 'eof' then
      self:error('unexpected end of input')
    end
    local k = self:kind()
    if (k == 'block' or k == 'header' or k == 'bare') and t.indent <= self.ref then
      self:error('a continuation line must be indented deeper than the line it continues', t)
    end
  end
end

-- Blocks and statements

function Parser:file()
  self:push('block', { indent = 0 })
  local stmts = {}
  while self.t.t ~= 'eof' do
    local t = self.t
    if is_closer(t) then self:unexpected(t) end
    if t.indent ~= 0 then self:error('unexpected indentation', t) end
    stmts[#stmts + 1] = self:statement()
    self:statement_end()
  end
  self:pop()
  return stmts
end

-- After a statement the next one has to start on a new line, unless a closing
-- bracket ends the block the statement is in.
function Parser:statement_end()
  local t = self.t
  if t.first then return end
  if is_closer(t) and self:in_bracket() then return end
  self:unexpected(t)
end

-- Parses the indented block on the following lines, or returns nil if there's none.
-- A block has to be indented deeper than the reference line (`self.ref`), the line
-- where the enclosing statement or bracket entry starts.
function Parser:block(item)
  local t = self.t
  if not t.first or t.t == 'eof' or t.indent <= self.ref then return nil end
  local indent = t.indent
  local saved_ref = self.ref
  self:push('block', { indent = indent })
  local stmts = {}

  while true do
    t = self.t
    if t.t == 'eof' then break end
    if is_closer(t) then
      if not self:in_bracket() then self:unexpected(t) end
      break
    end
    if t.indent < indent then break end
    if t.indent > indent then self:error('unexpected indentation', t) end
    self.ref = indent
    stmts[#stmts + 1] = (item or self.statement)(self)
    self:statement_end()
  end

  self:pop()
  self.ref = saved_ref
  return stmts
end

-- A body on the same line: a single statement, which inside call arguments or a
-- table can take the rest of the line's entries (see lists_allowed).
function Parser:inline_body()
  local k = self.ctx[#self.ctx].kind
  if k ~= 'call' and k ~= 'table' and k ~= 'bare' then
    return { self:statement() }
  end
  self:push('inline')
  local stmt = self:statement()
  self:pop()
  local t = self.t
  if is_op(t, ':') and t.sa and is_name_like(self.toks[self.i - 1]) then
    self:error('the inline body before this key takes the rest of the line, key included; put the key on a line of its own, or the function or block in parentheses',
      self.toks[self.i - 1])
  end
  return { stmt }
end

-- The body of a construct: a statement on the same line after `kw` (then/do), or an
-- indented block.
function Parser:body(kw)
  local t = self.t
  if kw and is_kw(t, kw) then
    self:advance()
    if self.t.first then
      return self:block() or self:error("expected a statement after '" .. kw .. "'")
    end
    return self:inline_body()
  end
  local b = t.first and self:block()
  if b then return b end
  if kw then
    self:error(string.format("expected '%s' or an indented block, found %s", kw, describe(t)), t)
  end
  self:error('expected an indented block', t)
end

-- A body that is a statement on the same line, or an indented block.
function Parser:inline_or_block(what)
  if self.t.first then
    return self:block() or self:error('expected an indented block after ' .. what)
  end
  return self:inline_body()
end

function Parser:statement()
  local saved_ref = self.ref
  local t = self.t
  self.ref = t.indent
  local stmt

  if t.t == 'keyword' then
    local v = t.v
    if v == 'if' or v == 'unless' then
      stmt = self:if_()
    elseif v == 'switch' then
      stmt = self:switch()
    elseif v == 'for' then
      stmt = self:for_()
    elseif v == 'while' then
      stmt = self:while_()
    elseif v == 'with' then
      stmt = self:with()
    elseif v == 'do' then
      stmt = self:do_()
    elseif v == 'class' then
      stmt = self:class()
    elseif v == 'export' then
      stmt = self:export()
    elseif v == 'local' then
      stmt = self:local_()
    elseif v == 'return' then
      stmt = self:return_()
    elseif v == 'break' then
      stmt = node('Break', self:advance())
    elseif v == 'continue' then
      stmt = node('Continue', self:advance())
    end
  end

  stmt = self:decorators(stmt or self:simple_statement())
  self.ref = saved_ref
  return stmt
end

-- Statement modifiers: `stmt if cond`, `stmt unless cond` and
-- `stmt for x in xs [if cond]`, which the AST calls decorators
function Parser:decorators(stmt)
  local t = self.t
  if t.first then return stmt end

  if is_kw(t, 'if') or is_kw(t, 'unless') then
    self:advance()
    local cond = self:cond()
    return node('If', stmt, {
      conds = { cond },
      bodies = { { stmt } },
      unless = t.v == 'unless',
      decorator = true,
    })
  elseif is_kw(t, 'for') and (self:kind() == 'block' or self:kind() == 'bare') then
    local head = self:for_head()
    local body = stmt
    local f = self:filter()
    if f then
      body = node('If', stmt, { conds = { f.cond }, bodies = { { stmt } }, unless = f.unless })
    end
    head.body = { body }
    head.line = stmt.line
    return head
  end

  return stmt
end

function Parser:target(e)
  if e.k == 'Table' then return self:pattern(e) end
  if assignable[e.k] then return e end
  if e.k == 'Call' or e.k == 'MethodCall' or e.k == 'WithCall' then
    raise("can't assign to the result of a call", e.line, e.col)
  end
  raise("can't assign to this expression", e.line, e.col)
end

function Parser:simple_statement()
  local t = self.t
  self.bare_at = self:kind() == 'block' and self.i or nil
  local exprs = self:expr_list()
  local nt = self.t

  if is_op(nt, '=') then
    local targets = {}
    for i, e in ipairs(exprs) do
      targets[i] = self:target(e)
    end
    self:advance()
    self:continuation()
    return node('Assign', t, { targets = targets, values = self:expr_list() })
  end

  if nt.t == 'op' and (update_ops[nt.v] or nt.v == '++' or nt.v == '--') then
    if #exprs > 1 then
      self:error("'" .. nt.v .. "' works on a single target", nt)
    end
    local target = self:target(exprs[1])
    if target.k == 'Pattern' then
      self:error("'" .. nt.v .. "' can't be used with destructuring", nt)
    end
    self:advance()
    if nt.v == '++' or nt.v == '--' then
      return node('Update', t, {
        target = target,
        op = nt.v == '++' and '+' or '-',
        value = node('Number', nt, { v = '1' }),
      })
    end
    self:continuation()
    return node('Update', t, { target = target, op = update_ops[nt.v], value = self:expr() })
  end

  return node('ExprStmt', t, { exprs = exprs })
end

function Parser:no_assignment()
  if is_op(self.t, '=') then
    self:error("assignment is not an expression; assign before the condition, or use '==' to compare")
  end
end

function Parser:cond()
  local e = self:expr()
  self:no_assignment()
  return e
end

-- the condition of a block construct, which ends at the end of the line
function Parser:header_cond()
  self:push('header')
  local cond = self:cond()
  self:pop()
  return cond
end

function Parser:if_()
  local t = self:advance()
  local ref = self.ref
  local unless = t.v == 'unless'
  local n = node('If', t, { conds = { self:header_cond() }, bodies = {}, unless = unless })
  n.bodies[1] = self:body('then')

  while true do
    local e = self.t
    -- `else` follows on the same line, or lines up with the line the if started on
    local aligned = not e.first or (e.t ~= 'eof' and e.indent == ref)
    if is_kw(e, 'elseif') and aligned and not unless then
      self:advance()
      n.conds[#n.conds + 1] = self:header_cond()
      n.bodies[#n.bodies + 1] = self:body('then')
    elseif is_kw(e, 'else') and aligned then
      self:advance()
      n.else_body = self:inline_or_block("'else'")
      break
    else
      break
    end
  end

  return n
end

function Parser:switch()
  local t = self:advance()
  local ref = self.ref
  local n = node('Switch', t, { subject = self:header_cond(), clauses = {} })
  local first = self.t
  if not first.first or first.t == 'eof' or first.indent <= ref then
    self:error("expected 'when' clauses on the following lines", first)
  end
  local indent = first.indent
  local saved_ref = self.ref
  self:push('block', { indent = indent })

  while true do
    local c = self.t
    if not c.first or c.t == 'eof' or c.indent ~= indent then break end
    self.ref = indent
    if is_kw(c, 'when') then
      self:advance()
      self:push('header')
      local values = self:expr_list()
      self:no_assignment()
      self:pop()
      n.clauses[#n.clauses + 1] = { values = values, body = self:body('then'), line = c.line }
    elseif is_kw(c, 'else') and #n.clauses > 0 then
      self:advance()
      n.else_body = self:inline_or_block("'else'")
      break
    else
      self:error("expected 'when'" .. (#n.clauses > 0 and " or 'else'" or ''), c)
    end
  end

  self:pop()
  self.ref = saved_ref
  return n
end

-- `for` up to its body: `for i = a, b[, step]`, `for names in exprs` or
-- `for name in *t`, where t can be a slice: `*t[a, b, step]`.
function Parser:for_head()
  local t = self:advance()
  self:push('header')
  local head
  local v = self.t

  if v.t == 'name' and is_op(self:peek(1), '=') then
    self:advance()
    self:advance()
    local start = self:expr()
    self:expect_op(',')
    local stop = self:expr()
    local step
    if self:accept_op(',') then step = self:expr() end
    head = node('For', t, { var = v.v, var_tok = v, start = start, stop = stop, step = step })
  else
    local vars = {}
    repeat
      local n = self.t
      if n.t == 'name' then
        self:advance()
        vars[#vars + 1] = node('Name', n, { v = n.v })
      elseif is_op(n, '{') then
        vars[#vars + 1] = self:pattern(self:table())
      else
        self:error('expected a loop variable, found ' .. describe(n), n)
      end
    until not self:accept_op(',')

    if not is_kw(self.t, 'in') then
      self:error("expected 'in' or '=' near " .. describe(self.t))
    end
    self:advance()

    if is_op(self.t, '*') then
      self:advance()
      if #vars > 1 then
        self:error("a loop over '*' takes a single variable", t)
      end
      head = node('ForIn', t, { vars = vars, star = self:expr() })
    else
      head = node('ForIn', t, { vars = vars, exprs = self:expr_list() })
    end
  end

  self:pop()
  return head
end

function Parser:for_()
  local head = self:for_head()
  head.body = self:body('do')
  return head
end

function Parser:while_()
  local t = self:advance()
  local cond = self:header_cond()
  return node('While', t, { cond = cond, body = self:body('do') })
end

function Parser:with()
  local t = self:advance()
  local target = self:header_cond()
  self.with_depth = self.with_depth + 1
  local body = self:block() or {}
  self.with_depth = self.with_depth - 1
  return node('With', t, { target = target, body = body })
end

function Parser:do_()
  local t = self:advance()
  return node('Do', t, { body = self:inline_or_block("'do'") })
end

function Parser:class()
  local t = self:advance()
  local n = self.t
  if n.t ~= 'name' then
    self:error('expected a class name, found ' .. describe(n), n)
  end
  self:advance()
  local parent
  if self.t.t == 'name' and self.t.v == 'extends' and not self.t.first then
    self:advance()
    self:push('header')
    parent = self:expr()
    self:pop()
  end
  return node('Class', t, {
    name = n.v,
    name_tok = n,
    parent = parent,
    body = self:block(self.class_item) or {},
  })
end

function Parser:class_item()
  local t, n = self.t, self:peek(1)

  -- `name: value`, `"name": value` and `[key]: value` define properties
  if (is_name_like(t) or t.t == 'string') and is_op(n, ':') and not n.sb and n.sa then
    self:advance()
    self:advance()
    local key = t.t == 'string' and self:string(t) or t.v
    return { k = 'prop', key = key, value = self:expr(), line = t.line, col = t.col }
  end

  if is_op(t, '[') then
    local close = self:matching(self.i)
    local after = close and self.toks[close + 1]
    if after and is_op(after, ':') and not after.sb and after.sa then
      self:advance()
      self:push('index')
      local key = self:expr()
      self:expect_closer(']', t)
      self:pop()
      self:advance()
      return { k = 'prop', key = key, value = self:expr(), line = t.line, col = t.col }
    end
  end

  -- `@name: value` sets a class variable
  if is_op(t, '@') and is_name_like(n) and not n.sb then
    local c = self:peek(2)
    if is_op(c, ':') and not c.sb and c.sa then
      self:advance()
      self:advance()
      self:advance()
      return { k = 'classvar', key = n.v, value = self:expr(), line = t.line, col = t.col }
    end
  end

  -- `:name` is short for `name: name`
  if is_op(t, ':') and not t.sa and n.t == 'name' and not n.sb then
    self:advance()
    self:advance()
    return { k = 'prop', key = n.v, value = node('Name', n, { v = n.v }), line = t.line, col = t.col }
  end

  return self:statement()
end

function Parser:names(what)
  local names = {}
  repeat
    local n = self.t
    if n.t ~= 'name' then
      self:error('expected a name to ' .. what .. ', found ' .. describe(n), n)
    end
    self:advance()
    names[#names + 1] = n
  until not self:accept_op(',')
  return names
end

function Parser:export()
  local t = self:advance()
  if self:accept_op('*') then
    return node('Export', t, { all = true })
  end
  if is_kw(self.t, 'class') then
    return node('Export', t, { class = self:class() })
  end
  local names = self:names('export')
  local values
  if self:accept_op('=') then
    self:continuation()
    values = self:expr_list()
  end
  return node('Export', t, { names = names, values = values })
end

function Parser:local_()
  local t = self:advance()
  local names = self:names('declare')
  local values
  if self:accept_op('=') then
    self:continuation()
    values = self:expr_list()
  end
  return node('Local', t, { names = names, values = values })
end

function Parser:return_()
  local t = self:advance()
  local n = self.t

  if n.first or is_closer(n) or (is_op(n, ',') and not self:lists_allowed()) then
    return node('Return', t, { values = {} })
  end

  if is_kw(n, 'if') or is_kw(n, 'unless') then
    -- `return if c` returns nothing when c holds. An if has no value to return, so
    -- `return if c then a else b` is an error.
    self:advance()
    local cond = self:header_cond()
    local after = self.t
    if is_kw(after, 'then') or (after.first and after.t ~= 'eof' and after.indent > self.ref) then
      self:error(string.format(
        "'%s' is a statement and gives no value; return in its branches instead", n.v), n)
    end
    return node('If', t, {
      conds = { cond },
      bodies = { { node('Return', t, { values = {} }) } },
      unless = n.v == 'unless',
      decorator = true,
    })
  end

  return node('Return', t, { values = self:expr_list() })
end

-- Expressions

function Parser:expr_list()
  local list = { self:expr() }
  while is_op(self.t, ',') and self:lists_allowed() and not self:ends_here() do
    self:advance()
    self:continuation()
    list[#list + 1] = self:expr()
  end
  return list
end

local function binop_priority(t)
  if t.t == 'op' then return binops[t.v] end
  if t.t == 'keyword' and (t.v == 'and' or t.v == 'or') then return binops[t.v] end
end

function Parser:expr(limit)
  limit = limit or 0
  local t = self.t
  local left

  if is_kw(t, 'not') or is_op(t, '-') or is_op(t, '#') then
    self:advance()
    left = node('Unop', t, { op = t.v, e = self:expr(UNARY_PRIORITY) })
  else
    left = self:primary()
  end

  while true do
    local op = self.t
    local priority = binop_priority(op)
    if not priority or priority[1] <= limit or self:ends_here() then break end
    self:advance()
    self:continuation()
    local right = self:expr(priority[2])
    left = node('Binop', left, { op = op.v, l = left, r = right })
  end

  return left
end

function Parser:primary()
  local t = self.t
  local tt, v = t.t, t.v
  local e, name_end
  local at_start = self.i == self.bare_at

  if tt == 'name' then
    self:advance()
    if v == 'super' then
      e = node('Super', t)
    else
      e = node('Name', t, { v = v })
      name_end = true
    end
  elseif tt == 'number' then
    self:advance()
    e = node('Number', t, { v = v })
  elseif tt == 'string' then
    self:advance()
    e = self:string(t)
  elseif tt == 'keyword' then
    if v == 'nil' or v == 'true' or v == 'false' then
      self:advance()
      e = node(v == 'nil' and 'Nil' or v == 'true' and 'True' or 'False', t)
    elseif v == 'if' or v == 'unless' or v == 'switch' then
      self:error(string.format(
        "'%s' is a statement and gives no value; assign or return in its branches instead", v))
    elseif v == 'for' or v == 'while' then
      self:error(string.format(
        "'%s' is a statement and gives no value; collect values with a comprehension, as in [x * 2 for x in *t]", v))
    elseif v == 'do' then
      self:error("'do' is a statement and gives no value; assign or return inside it instead")
    -- a with block as a value takes no postfix operators: it ends with its body
    elseif v == 'with' then
      return self:with()
    elseif v == 'class' then
      self:error('a class can only be declared as a statement')
    else
      self:unexpected(t)
    end
  elseif tt == 'op' then
    if v == '...' then
      self:advance()
      e = node('Vararg', t)
    elseif v == '@' or v == '@@' then
      e, name_end = self:self_ref()
    elseif v == '(' then
      e = self:paren_or_func()
      if e.k == 'Func' then return e end
    elseif v == '->' or v == '=>' then
      return self:func(nil, t)
    elseif v == '{' then
      e = self:table()
    elseif v == '[' then
      e = self:list_comprehension()
    elseif v == '.' then
      e, name_end = self:with_field()
    elseif v == ':' then
      e = self:with_call(at_start)
    else
      self:unexpected(t)
    end
  else
    self:error('unexpected ' .. describe(t), t)
  end

  return self:postfix(e, name_end, at_start)
end

function Parser:self_ref()
  local t = self:advance()
  local n = self.t
  if is_name_like(n) and not n.sb then
    self:advance()
    return node(t.v == '@' and 'SelfField' or 'ClassField', t, { name = n.v }), true
  end
  return node(t.v == '@' and 'Self' or 'ClassRef', t), false
end

-- the arguments of a method call: `(...)`, a single touching string or, when
-- `at_start` of a statement, arguments without parentheses
function Parser:method_args(name, colon, at_start)
  local t = self.t
  if is_op(t, '(') and not t.sb then
    return self:call_args()
  elseif t.t == 'string' and not t.sb and t.q ~= '[' then
    self:advance()
    return { self:string(t) }
  elseif self:bare_call(at_start) then
    return self:bare_args()
  end
  self:error(string.format(
    "method reference without a call; wrap it in a function, as in (...) -> obj:%s(...), or add a space after ':' for a key",
    name), colon)
end

-- `.field`, `[index]`, `(call)`, `:method(call)` and `'string call'`, which all have
-- to touch what they apply to. `name_end` is set when the expression so far ends
-- with a name, which a touching string literal makes a call. When the expression
-- starts a statement (`at_start`), arguments without parentheses can end it.
function Parser:postfix(e, name_end, at_start)
  while true do
    local t = self.t
    if t.sb then
      if (name_end or e.k == 'Super') and self:bare_call(at_start) then
        return node('Call', e, { fn = e, args = self:bare_args() })
      end
      break
    end

    if is_op(t, '.') then
      self:advance()
      local n = self.t
      if not is_name_like(n) or n.sb then
        self:error("expected a field name after '.'", n)
      end
      self:advance()
      e = node('Field', e, { obj = e, name = n.v })
      name_end = true
    elseif is_op(t, '[') then
      e = self:index(e)
      name_end = false
    elseif is_op(t, '(') then
      e = node('Call', e, { fn = e, args = self:call_args() })
      name_end = false
    elseif is_op(t, ':') then
      local n = self:peek(1)
      if t.sa or not is_name_like(n) or n.sb then break end
      self:advance()
      self:advance()
      local bare = self.t.sb
      e = node('MethodCall', e, { obj = e, name = n.v, args = self:method_args(n.v, t, at_start) })
      if bare then return e end
      name_end = false
    elseif t.t == 'string' and name_end and t.q ~= '[' then
      self:advance()
      e = node('Call', e, { fn = e, args = { self:string(t) } })
      name_end = false
    else
      break
    end
  end
  return e
end

function Parser:index(obj)
  local open = self:advance()
  self:push('index')
  local parts = {}
  local slice = false

  if is_op(self.t, ',') then
    parts[1] = false
  else
    parts[1] = self:expr()
  end
  while self:accept_op(',') do
    slice = true
    if is_op(self.t, ',') or is_op(self.t, ']') then
      parts[#parts + 1] = false
    else
      parts[#parts + 1] = self:expr()
    end
  end

  self:expect_closer(']', open)
  self:pop()

  if slice then
    if #parts > 3 then
      raise('a slice takes at most three parts: [start, stop, step]', open.line, open.col)
    end
    return node('Slice', obj, {
      obj = obj,
      start = parts[1] or nil,
      stop = parts[2] or nil,
      step = parts[3] or nil,
    })
  end
  return node('Index', obj, { obj = obj, key = parts[1] })
end

-- What the entry starting at the current token is: 'named' (key: value),
-- 'string_key' ("key": value), 'expr_key' ([key]: value), 'shorthand' (:name), or
-- 'pos' (a plain value).
function Parser:entry_kind()
  local t, n = self.t, self:peek(1)

  if (is_name_like(t) or t.t == 'string') and is_op(n, ':') and not n.sb then
    if n.sa then
      return t.t == 'string' and 'string_key' or 'named'
    end
    local n2 = self:peek(2)
    if is_name_like(n2) and not n2.sb then return 'pos' end -- a method call
    self:error("add a space after ':' when giving a key", n)
  end

  if is_op(t, ':') and not t.sa and is_name_like(n) and not n.sb then
    local n2 = self:peek(2)
    if (is_op(n2, '(') or n2.t == 'string') and not n2.sb then
      return 'pos' -- a call in a with block
    end
    if n.t ~= 'name' then
      self:error(string.format("'%s' is a keyword and can't be used as a variable", n.v), n)
    end
    return 'shorthand'
  end

  if is_op(t, '[') then
    local close = self:matching(self.i)
    local after = close and self.toks[close + 1]
    if after and is_op(after, ':') and not after.sb then
      if not after.sa then
        self:error("add a space after ':' when giving a key", after)
      end
      return 'expr_key'
    end
  end

  return 'pos'
end

function Parser:entry(kind)
  local t = self.t

  if kind == 'shorthand' then
    self:advance()
    local n = self:advance()
    return { k = 'named', key = n.v, v = node('Name', n, { v = n.v }), line = t.line }
  end

  local key
  if kind == 'named' then
    key = self:advance().v
  elseif kind == 'string_key' then
    key = self:string(self:advance())
  else
    self:advance()
    self:push('index')
    key = self:expr()
    self:expect_closer(']', t)
    self:pop()
  end
  self:advance() -- the ':'

  -- a nested implicit table, as in `title: get: => ...`, needs braces
  local k2, colon = self.t, self:peek(1)
  if is_name_like(k2) and is_op(colon, ':') and not colon.sb and colon.sa then
    self:error("wrap the value in {}; only a call's own arguments can leave out the braces", k2)
  end

  local value = self:expr()
  if kind == 'named' then
    return { k = 'named', key = key, v = value, line = t.line }
  end
  return { k = 'expr', key = key, v = value, line = t.line }
end

-- Consumes the separator after an entry in call arguments or a table: a ',' or a
-- line break. Returns false at the closing bracket.
function Parser:separator(closer)
  local t = self.t
  if is_op(t, ',') then
    self:advance()
    return true
  end
  if is_op(t, closer) then return false end
  if t.first and t.t ~= 'eof' then return true end
  if t.t == 'eof' then return true end -- reported as unclosed by the caller
  self:unexpected(t)
end

-- Parses an argument of a call into `args`, or into the table `named` collecting the
-- trailing named ones, which it returns.
function Parser:argument(args, named)
  local t = self.t
  local saved_ref = self.ref
  self.ref = t.indent
  local kind = self:entry_kind()
  if kind == 'pos' then
    if named then
      self:error('positional arguments must come before the named ones', t)
    end
    args[#args + 1] = self:expr()
  else
    named = named or node('Table', t, { entries = {}, implicit = true })
    named.entries[#named.entries + 1] = self:entry(kind)
  end
  self.ref = saved_ref
  return named
end

function Parser:call_args()
  local open = self:advance()
  self:push('call')
  local args, named = {}, nil

  while not is_op(self.t, ')') do
    local t = self.t
    if t.t == 'eof' then
      self:error(string.format("unclosed '(' from line %d", open.line), t)
    end
    named = self:argument(args, named)
    if not self:separator(')') then break end
  end

  self:expect_closer(')', open)
  self:pop()
  if named then args[#args + 1] = named end
  return args
end

-- Whether the current token can start the arguments of a call without parentheses:
-- it's on the same line after a space, and starts a value that can't continue the
-- expression before it. So `f -1` stays a subtraction and `f (x)` and `f [x]` stay
-- errors, while `f (x) -> x` passes a function.
function Parser:starts_bare_args()
  local t = self.t
  if t.first or not t.sb then return false end
  local tt, v = t.t, t.v
  if tt == 'name' or tt == 'number' or tt == 'string' then return true end
  if tt == 'keyword' then
    return v == 'not' or v == 'nil' or v == 'true' or v == 'false'
  end
  if tt ~= 'op' then return false end
  if v == '{' or v == '@' or v == '@@' or v == '->' or v == '=>' or v == '...' or v == '#' then
    return true
  end
  if v == ':' or v == '.' then -- :name (short for name: name), or .field of a with
    local n = self:peek(1)
    return not t.sa and is_name_like(n) and not n.sb
  end
  if v == '(' then
    local close = self:matching(self.i)
    local after = close and self.toks[close + 1]
    return after ~= nil and (is_op(after, '->') or is_op(after, '=>'))
  end
  return false
end

-- Whether arguments without parentheses start at the current token. They're
-- allowed when the call starts a statement directly in a block (`at_start`), and an
-- error anywhere else but in a block header, where the token more likely starts the
-- body after a missing 'then' or 'do'; that's left to the header to report.
function Parser:bare_call(at_start)
  if not self:starts_bare_args() then return false end
  if at_start then return true end
  for i = #self.ctx, 1, -1 do
    local k = self.ctx[i].kind
    if k == 'block' then break end
    if k == 'header' then return false end
    if k == 'bare' then
      self:error('a call in the arguments of a call without parentheses needs parentheses, as in f x, g(y)')
    end
    if k ~= 'inline' then
      self:error('a call inside brackets needs parentheses, as in f(x)')
    end
  end
  self:error('only a call that is a statement of its own can leave out its parentheses; write f(x) here')
end

-- The arguments of a call without parentheses, which run to the end of the line.
function Parser:bare_args()
  self:push('bare')
  local args = {}
  local named = self:argument(args)
  while is_op(self.t, ',') and not self:ends_here() do
    self:advance()
    self:continuation()
    named = self:argument(args, named)
  end
  self:pop()
  if named then args[#args + 1] = named end
  return args
end

function Parser:table()
  local open = self:advance()
  self:push('table')
  local entries = {}

  while not is_op(self.t, '}') do
    local t = self.t
    if t.t == 'eof' then
      self:error(string.format("unclosed '{' from line %d", open.line), t)
    end
    local saved_ref = self.ref
    self.ref = t.indent
    local kind = self:entry_kind()
    if kind == 'pos' then
      entries[#entries + 1] = { k = 'pos', v = self:expr(), line = t.line }
    else
      entries[#entries + 1] = self:entry(kind)
    end
    self.ref = saved_ref

    -- `{k, v for ...}` and `{e for ...}` are table comprehensions
    if is_kw(self.t, 'for') then
      local n = #entries
      if n > 2 or entries[1].k ~= 'pos' or (n == 2 and entries[2].k ~= 'pos') then
        self:error('a table comprehension takes a key and a value, as in {k, v for k, v in pairs(t)}')
      end
      local clauses = self:comprehension_clauses()
      self:expect_closer('}', open)
      self:pop()
      return node('Comprehension', open, {
        kind = 'table',
        kexpr = entries[1].v,
        vexpr = entries[2] and entries[2].v,
        clauses = clauses,
      })
    end

    if not self:separator('}') then break end
  end

  self:expect_closer('}', open)
  self:pop()
  return node('Table', open, { entries = entries })
end

-- The `if cond` or `unless cond` filtering a comprehension's or a for modifier's
-- values, if there's one there.
function Parser:filter()
  local t = self.t
  if self:ends_here() then return nil end
  if is_kw(t, 'when') then
    self:error("filter with 'if' or 'unless' rather than 'when', as in [x for x in *t if x > 0]", t)
  end
  if not (is_kw(t, 'if') or is_kw(t, 'unless')) then return nil end
  self:advance()
  self:push('header')
  local cond = self:cond()
  self:pop()
  return { k = 'filter', cond = cond, unless = t.v == 'unless', line = t.line }
end

function Parser:list_comprehension()
  local open = self:advance()
  self:push('compr')
  local expr = self:expr()
  local t = self.t
  if is_kw(t, 'if') or is_kw(t, 'unless') then
    self:error(string.format("a comprehension's '%s' goes after its 'for', as in [x for x in *t if x > 0]", t.v), t)
  end
  if not is_kw(self.t, 'for') then
    self:error("expected 'for' in a list comprehension; table literals use {}", self.t)
  end
  local clauses = self:comprehension_clauses()
  self:expect_closer(']', open)
  self:pop()
  return node('Comprehension', open, { kind = 'list', expr = expr, clauses = clauses })
end

-- A comprehension's single for clause, and the filter that can follow it. Several
-- loops or filters make for an unreadable comprehension, so they're errors.
function Parser:comprehension_clauses()
  local clauses = { self:for_head() }
  clauses[2] = self:filter()
  local t = self.t
  if is_kw(t, 'for') then
    self:error("a comprehension takes a single 'for'; go over several with nested for loops", t)
  elseif is_kw(t, 'if') or is_kw(t, 'unless') then
    self:error("a comprehension takes a single filter; combine the conditions with 'and'", t)
  end
  return clauses
end

function Parser:paren_or_func()
  local open = self.t
  local close = self:matching(self.i)
  local after = close and self.toks[close + 1]
  if after and (is_op(after, '->') or is_op(after, '=>')) then
    return self:func(self:params(), open)
  end

  self:advance()
  self:push('group')
  local e = self:expr()
  self:expect_closer(')', open)
  self:pop()
  return node('Paren', open, { e = e })
end

function Parser:params()
  local open = self:advance()
  self:push('group')
  local params = {}

  while not is_op(self.t, ')') do
    local t = self.t
    local p = { tok = t }
    local n = self:peek(1)
    if t.t == 'name' and t.v == 'using' and (n.t == 'name' or is_kw(n, 'nil')) then
      self:error("Howlscript has no 'using'; parameters may not shadow locals, so name them apart instead")
    end
    if is_op(t, '...') then
      self:advance()
      p.vararg = true
    elseif is_op(t, '@') then
      local n = self:peek(1)
      if n.t ~= 'name' or n.sb then
        self:error("expected a name after '@'", n)
      end
      self:advance()
      self:advance()
      p.name = n.v
      p.tok = n
      p.self_assign = true
    elseif t.t == 'name' then
      self:advance()
      p.name = t.v
    elseif is_op(t, '{') then
      p.pattern = self:pattern(self:table())
    else
      self:error('expected a parameter, found ' .. describe(t), t)
    end

    if is_op(self.t, '=') then
      if p.vararg then self:error("'...' can't have a default value") end
      self:advance()
      p.default = self:expr()
    end
    if params[#params] and params[#params].vararg then
      self:error("'...' must be the last parameter", t)
    end
    params[#params + 1] = p
    if self.t.t == 'name' and self.t.v == 'using' then
      self:error("Howlscript has no 'using'; parameters may not shadow locals, so name them apart instead")
    end
    if not self:accept_op(',') then break end
  end

  self:expect_closer(')', open)
  self:pop()
  return params
end

function Parser:func(params, start)
  local arrow = self:advance()
  local n = node('Func', start, { params = params or {}, fat = arrow.v == '=>' })
  local t = self.t
  if t.first then
    n.body = self:block() or {}
  elseif is_closer(t) or is_op(t, ',') then
    n.body = {}
  else
    n.body = self:inline_body()
  end
  return n
end

function Parser:with_field()
  local dot = self:advance()
  local n = self.t
  if not is_name_like(n) or n.sb then
    self:error("expected a name after '.'", n)
  end
  if self.with_depth == 0 then
    self:error(string.format("'.%s' refers to the target of a with block, but there's none here", n.v), dot)
  end
  self:advance()
  return node('WithField', dot, { name = n.v }), true
end

function Parser:with_call(at_start)
  local colon = self:advance()
  local n = self.t
  if colon.sa or not is_name_like(n) or n.sb then
    self:error("unexpected ':'", colon)
  end
  if self.with_depth == 0 then
    self:error(string.format("':%s()' calls a method on the target of a with block, but there's none here", n.v), colon)
  end
  self:advance()
  return node('WithCall', colon, { name = n.v, args = self:method_args(n.v, colon, at_start) })
end

function Parser:string(t)
  local parts = {}
  for i, p in ipairs(t.parts) do
    if type(p) == 'string' then
      parts[i] = p
    else
      local sub = new_parser(p.tokens, self.with_depth)
      sub:push('group')
      parts[i] = sub:expr()
      if sub.t.t ~= 'eof' then sub:unexpected(sub.t) end
    end
  end
  return node('String', t, { q = t.q, parts = parts })
end

-- Converts a table literal used as an assignment target into a Pattern.
function Parser:pattern(tbl)
  if tbl.k ~= 'Table' then
    raise("a comprehension can't be assigned to", tbl.line, tbl.col)
  end
  local entries = {}
  for i, e in ipairs(tbl.entries) do
    local target = e.v
    if target.k == 'Table' or target.k == 'Comprehension' then
      target = self:pattern(target)
    elseif not assignable[target.k] then
      raise("can't destructure into this expression", target.line, target.col)
    end
    entries[i] = { k = e.k, key = e.key, target = target, line = e.line }
  end
  return node('Pattern', tbl, { entries = entries })
end

local function parse(tokens)
  return new_parser(tokens):file()
end

return {
  parse = parse,
}
