-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Compiles the AST from the parser into Lua, in a single pass that also resolves
-- names: an assignment to a name that isn't visible declares a new local.
--
-- Blocks used as values (if, switch, with, do, loops, comprehensions) are lowered
-- with a "sink" saying what to do with the value of their last statement: return
-- it, assign it, accumulate it into a table, or discard it. When such a block is
-- assigned or returned it's lowered in place; anywhere else in an expression it
-- becomes an immediately called function (an IIFE).
--
-- Generated names start with `__hs`, which the lexer doesn't allow in source.

-- The JIT only slows code this recursive and branchy down: it keeps recording
-- traces that abort, which made compiling several times slower.
jit.off(true, true)

local Scope = require('howlscript.scope')
local Emitter = require('howlscript.emitter')
local raise = require('howlscript.errors').raise

local concat = table.concat
-- string functions are used directly rather than as methods, since Howl gives
-- strings an __index function that makes method calls slow
local format, match, lower = string.format, string.match, string.lower

local lua_keywords = {}
for kw in ([[
  and break do else elseif end false for function goto if in local nil not or
  repeat return then true until while
]]):gmatch('%a+') do
  lua_keywords[kw] = true
end

-- Lua keywords that Howlscript doesn't reserve, so they can reach the compiler as names
local lua_only = { ['end'] = true, ['function'] = true, ['goto'] = true, ['repeat'] = true, ['until'] = true }

local function valid_name(s)
  return not lua_keywords[s] and match(s, '^[%a_][%w_]*$') ~= nil
end

local function field(name)
  if valid_name(name) then return '.' .. name end
  return '[' .. format('%q', name) .. ']'
end

local function key(name)
  if valid_name(name) then return name end
  return '[' .. format('%q', name) .. ']'
end

-- Lua operator precedences, for parenthesizing
local precedence = {
  ['or'] = 1, ['and'] = 2,
  ['<'] = 3, ['>'] = 3, ['<='] = 3, ['>='] = 3, ['=='] = 3, ['~='] = 3, ['!='] = 3,
  ['..'] = 4, ['+'] = 5, ['-'] = 5, ['*'] = 6, ['/'] = 6, ['%'] = 6, ['^'] = 8,
}
local UNARY = 7

local value_blocks = {
  If = true, Switch = true, With = true, Do = true, For = true, ForIn = true,
  While = true, Comprehension = true,
}
local loops = { For = true, ForIn = true, While = true }
local calls = { Call = true, MethodCall = true, WithCall = true }

-- what Lua accepts as the receiver of a call, index or field access without
-- parentheses (immediately called functions included)
local prefix_kinds = {
  Name = true, Field = true, Index = true, Call = true, MethodCall = true,
  WithCall = true, Paren = true, Self = true, SelfField = true, ClassRef = true,
  ClassField = true, WithField = true, Raw = true, Super = true,
}
for k in pairs(value_blocks) do prefix_kinds[k] = true end

local function raw(code)
  return { k = 'Raw', code = code }
end

-- Expressions that are cheap and without side effects, so they can be evaluated
-- more than once.
local function is_simple(e)
  local k = e.k
  if k == 'Name' or k == 'Self' or k == 'SelfField' or k == 'Number' or k == 'Raw'
    or k == 'Nil' or k == 'True' or k == 'False' then
    return true
  end
  if k == 'String' then
    for _, p in ipairs(e.parts) do
      if type(p) ~= 'string' then return false end
    end
    return true
  end
  return false
end

-- Expressions that are plain lookups, repeated for each name a pattern extracts.
local function is_path(e)
  local k = e.k
  if k == 'Name' or k == 'Self' or k == 'SelfField' or k == 'Raw' then return true end
  return k == 'Field' and is_path(e.obj)
end

-- Whether a loop body has a `continue` for the loop itself.
local stops_continue = { For = true, ForIn = true, While = true, Func = true, Comprehension = true }
local function has_continue(n)
  if n.k == 'Continue' then return true end
  if n.k and stops_continue[n.k] then return false end
  for _, v in pairs(n) do
    if type(v) == 'table' and has_continue(v) then return true end
  end
  return false
end

-- Whether any of `names` occurs as a name in a node.
local function mentions(n, names)
  if n.k == 'Name' and names[n.v] then return true end
  for _, v in pairs(n) do
    if type(v) == 'table' and mentions(v, names) then return true end
  end
  return false
end

local DISCARD = { k = 'discard' }
local IMPLICIT_RETURN = { k = 'return', implicit = true }

local Compiler = {}
Compiler.__index = Compiler

-- the stmt_<Kind> and e_<Kind> methods by node kind, filled in at the end
local stmt_handlers, expr_handlers = {}, {}

local function new(source)
  return setmetatable({
    E = Emitter.new(source),
    n_tmp = 0,
    with_stack = {},
    cls = nil,     -- the class being compiled: { c, b, p, method }
    fn = nil,      -- the function being compiled: { vararg, iife, loop }
    scope = nil,
    needs_invoke = false,
  }, Compiler)
end

function Compiler:error(message, n)
  raise(message, n.line or 1, n.col or 1)
end

function Compiler:tmp(what)
  self.n_tmp = self.n_tmp + 1
  return '__hs_' .. what .. self.n_tmp
end

function Compiler:push_scope()
  self.scope = Scope.new(self.scope)
end

function Compiler:pop_scope()
  self.scope = self.scope.parent
end

function Compiler:check_name(name, n)
  if lua_only[name] then
    self:error(format("'%s' is a Lua keyword and can't be used as a variable name", name), n)
  end
end

function Compiler:declare_all(names, line)
  for _, name in ipairs(names) do
    self.scope:declare(name, line)
  end
end

-- Declares a parameter or loop variable, which may not shadow a visible local.
function Compiler:bind(name, n, what)
  self:check_name(name, n)
  if name ~= '_' and name ~= 'self' then
    local decl = self.scope:lookup(name)
    if decl then
      self:error(format(
        "%s '%s' shadows the local declared on line %d; rename one of them",
        what, name, decl.line), n)
    end
  end
  self.scope:declare(name, n.line)
end

function Compiler:need_self(n)
  if not self.scope:lookup('self') then
    self:error("'@' refers to self, but there's none here; methods are defined with '=>'", n)
  end
end

function Compiler:with_var(n)
  local var = self.with_stack[#self.with_stack]
  if not var then
    self:error('this refers to the target of a with block, but there is none here', n)
  end
  return var
end

function Compiler:super_cls(n, need_method)
  local cls = self.cls
  if not cls or (need_method and not cls.method) then
    self:error("'super' can only be used in a class method", n)
  end
  if not cls.p then
    self:error("'super' needs a parent class, given with 'extends'", n)
  end
  return cls
end

-- Blocks and sinks

function Compiler:stmt(s)
  local handler = stmt_handlers[s.k]
  if not handler then
    self:error('unexpected ' .. s.k, s)
  end
  handler(self, s)
end

-- Compiles a list of statements. The last one's value goes to `sink`, and with
-- `wrap_last` a final return or break is wrapped in do ... end, since Lua code
-- follows it.
function Compiler:block(stmts, sink, wrap_last)
  if sink == DISCARD then sink = nil end
  local n = #stmts
  for i = 1, n do
    local s = stmts[i]
    if i < n and (s.k == 'Return' or s.k == 'Break' or s.k == 'Continue') then
      self:error("unreachable code after '" .. lower(s.k) .. "'", stmts[i + 1])
    end
    if i < n then
      self:stmt(s)
    elseif sink then
      self:tail(s, sink, wrap_last)
    elseif wrap_last and (s.k == 'Return' or s.k == 'Break') then
      stmt_handlers[s.k](self, s, true)
    else
      self:stmt(s)
    end
  end
end

-- Compiles the last statement of a block, sending its value to the sink.
function Compiler:tail(s, sink, wrap)
  local k = s.k
  if k == 'ExprStmt' then
    if #s.exprs == 1 and value_blocks[s.exprs[1].k] then
      return self:lower(s.exprs[1], sink)
    end
    if sink.k == 'discard' then return self:stmt_ExprStmt(s) end
    return self:apply(sink, s.exprs, s.line)
  elseif k == 'If' or k == 'Switch' or k == 'With' or k == 'Do' or loops[k] then
    return self:lower(s, sink)
  elseif k == 'Return' or k == 'Break' then
    return stmt_handlers[k](self, s, wrap)
  elseif k == 'Continue' then
    return self:stmt(s)
  elseif sink.k ~= 'discard' and (k == 'Class' or (k == 'Export' and s.class)) then
    self:stmt(s)
    local name = k == 'Class' and s.name or s.class.name
    return self:apply(sink, { { k = 'Name', v = name } })
  end

  self:stmt(s)
  -- a block ending in a statement without a value has the value nil
  if sink.k == 'assign' and not sink.fresh then
    self:apply(sink, { { k = 'Nil' } })
  end
end

-- Sends the values of `exprs` to the sink.
function Compiler:apply(sink, exprs, line)
  local E = self.E
  local k = sink.k
  if k == 'discard' then
    return self:stmt_ExprStmt({ k = 'ExprStmt', exprs = exprs, line = line, col = exprs[1].col })
  end
  E:stmt(line)
  if k == 'return' then
    E:w('return ')
    self:expr_list(exprs)
  elseif k == 'assign' then
    self:targets(sink.targets)
    E:w(' = ')
    self:expr_list(exprs)
  elseif k == 'accum' then
    local n = sink.n
    E:w(format('%s = %s + 1; %s[%s] = ', n, n, sink.acc, n))
    self:expr(exprs[1])
  end
end

-- Lowers a block used as a value in place, sending its value to the sink.
function Compiler:lower(e, sink)
  local k = e.k
  if k == 'If' then
    return self:lower_if(e, sink)
  elseif k == 'Switch' then
    return self:lower_switch(e, sink)
  elseif k == 'With' then
    return self:lower_with(e, sink)
  elseif k == 'Do' then
    return self:lower_do(e, sink)
  elseif loops[k] then
    -- loops only collect their values when used as values, not as statements
    -- or as the last statement of a function
    if sink.k == 'discard' or sink.implicit then
      return self:loop(e)
    end
    return self:lower_loop(e, sink)
  elseif k == 'Comprehension' then
    if sink.k == 'discard' then
      self:error('this comprehension does nothing; only calls can be statements', e)
    end
    return self:lower_comprehension(e, sink)
  end
  return self:apply(sink, { e }, e.line)
end

-- When a value block without a fallback branch assigns to existing names, the
-- missing branch assigns nil, as the block's value is nil then.
function Compiler:nil_branch(sink)
  if sink and sink.k == 'assign' and not sink.fresh then
    self.E:sp()
    self.E:w('else')
    self:apply(sink, { { k = 'Nil' } })
  end
end

function Compiler:lower_if(s, sink)
  local E = self.E
  E:stmt(s.line)

  -- `x = 1 if c` declares x outside the if, where it can be used
  local inner = s.decorator and s.bodies[1][1]
  if inner and inner.k == 'Assign' then
    local fresh, seen = {}, {}
    for _, t in ipairs(inner.targets) do
      if t.k == 'Name' and self.scope:is_fresh(t.v) and not seen[t.v] then
        self:check_name(t.v, t)
        fresh[#fresh + 1] = t.v
        seen[t.v] = true
      end
    end
    if #fresh > 0 then
      E:w('local ' .. concat(fresh, ', ') .. '; ')
      self:declare_all(fresh, s.line)
    end
  end

  for i, cond in ipairs(s.conds) do
    if i == 1 then
      E:w('if ')
    else
      E:sp(cond.line)
      E:w('elseif ')
    end
    if i == 1 and s.unless then
      E:w('not ')
      self:expr(cond, UNARY)
    else
      self:expr(cond)
    end
    E:w(' then')
    self:push_scope()
    self:block(s.bodies[i], sink)
    self:pop_scope()
  end

  if s.else_body then
    E:sp()
    E:w('else')
    self:push_scope()
    self:block(s.else_body, sink)
    self:pop_scope()
  else
    self:nil_branch(sink)
  end
  E:sp()
  E:w('end')
end

function Compiler:lower_switch(s, sink)
  local E = self.E
  E:stmt(s.line)
  local subject = s.subject
  local tmp
  if not is_simple(subject) then
    tmp = self:tmp('switch')
    E:w('do local ' .. tmp .. ' = ')
    self:expr(subject)
    E:w(';')
    subject = raw(tmp)
  end

  for i, clause in ipairs(s.clauses) do
    if i == 1 then
      E:sp()
      E:w('if ')
    else
      E:sp(clause.line)
      E:w('elseif ')
    end
    -- the case value goes on the left, so its __eq is the one used
    local cond
    for _, v in ipairs(clause.values) do
      local test = { k = 'Binop', op = '==', l = v, r = subject, line = v.line }
      cond = cond and { k = 'Binop', op = 'or', l = cond, r = test, line = cond.line } or test
    end
    self:expr(cond)
    E:w(' then')
    self:push_scope()
    self:block(clause.body, sink)
    self:pop_scope()
  end

  if s.else_body then
    E:sp()
    E:w('else')
    self:push_scope()
    self:block(s.else_body, sink)
    self:pop_scope()
  else
    self:nil_branch(sink)
  end
  E:sp()
  E:w(tmp and 'end end' or 'end')
end

function Compiler:lower_with(s, sink)
  local E = self.E
  local var = self:tmp('with')
  E:stmt(s.line)
  E:w('do local ' .. var .. ' = ')
  self:expr(s.target)
  self.with_stack[#self.with_stack + 1] = var
  self:push_scope()
  self:block(s.body, nil)
  self:pop_scope()
  self.with_stack[#self.with_stack] = nil
  -- the value of a with block is its target
  if sink and sink.k ~= 'discard' then
    self:apply(sink, { raw(var) })
  end
  E:sp()
  E:w('end')
end

function Compiler:lower_do(s, sink)
  local E = self.E
  E:stmt(s.line)
  E:w('do')
  self:push_scope()
  self:block(s.body, sink)
  self:pop_scope()
  E:sp()
  E:w('end')
end

-- Emits the head of a loop or comprehension clause, up to and including its 'do',
-- binding the loop variables. Returns how many 'end's close it.
function Compiler:loop_head(s)
  local E = self.E

  if s.k == 'For' then
    E:w('for ' .. s.var .. ' = ')
    self:expr(s.start)
    E:w(', ')
    self:expr(s.stop)
    if s.step then
      E:w(', ')
      self:expr(s.step)
    end
    E:w(' do')
    self:bind(s.var, s.var_tok, 'loop variable')
    return 1
  elseif s.k == 'While' then
    E:w('while ')
    self:expr(s.cond)
    E:w(' do')
    return 1
  end

  if s.star then
    local list, i = self:tmp('list'), self:tmp('i')
    local star, start, stop, step = s.star, nil, nil, nil
    if star.k == 'Slice' then
      start, stop, step, star = star.start, star.stop, star.step, star.obj
    end
    E:w('do local ' .. list .. ' = ')
    self:expr(star)
    E:w('; for ' .. i .. ' = ')
    if start then self:expr(start) else E:w('1') end
    E:w(', ')
    if stop then self:expr(stop) else E:w('#' .. list) end
    if step then
      E:w(', ')
      self:expr(step)
    end
    E:w(' do')
    local var = s.vars[1]
    local item = list .. '[' .. i .. ']'
    if var.k == 'Pattern' then
      self:bind_pattern(var, raw(item), 'loop variable')
    else
      E:w(' local ' .. var.v .. ' = ' .. item)
      self:bind(var.v, var, 'loop variable')
    end
    return 2
  end

  local names, patterns = {}, {}
  for i, var in ipairs(s.vars) do
    if var.k == 'Pattern' then
      names[i] = self:tmp('item')
      patterns[#patterns + 1] = { var, names[i] }
    else
      names[i] = var.v
    end
  end
  E:w('for ' .. concat(names, ', ') .. ' in ')
  self:expr_list(s.exprs)
  E:w(' do')
  for _, var in ipairs(s.vars) do
    if var.k == 'Name' then self:bind(var.v, var, 'loop variable') end
  end
  for _, p in ipairs(patterns) do
    self:bind_pattern(p[1], raw(p[2]), 'loop variable')
  end
  return 1
end

-- Emits a loop. With `acc`, an 'accum' sink, each iteration's value is collected.
function Compiler:loop(s, acc)
  local E = self.E
  local loop = { label = has_continue(s.body) and self:tmp('continue') or nil }
  E:stmt(s.line)
  self:push_scope()
  local closes = self:loop_head(s)
  local saved = self.fn.loop
  self.fn.loop = loop
  self:block(s.body, acc, loop.label ~= nil)
  self.fn.loop = saved
  if loop.label then
    -- a label ending the body is outside the scope of the body's locals, so the
    -- gotos can jump past them
    E:sp()
    E:w('::' .. loop.label .. '::')
  end
  for _ = 1, closes do
    E:sp()
    E:w('end')
  end
  self:pop_scope()
end

function Compiler:lower_loop(s, sink)
  local E = self.E
  local acc, n = self:tmp('acc'), self:tmp('n')
  E:stmt(s.line)
  E:w(format('do local %s, %s = {}, 0', acc, n))
  self:loop(s, { k = 'accum', acc = acc, n = n })
  self:apply(sink, { raw(acc) })
  E:sp()
  E:w('end')
end

function Compiler:lower_comprehension(c, sink)
  local E = self.E
  local acc = self:tmp('acc')
  local n = c.kind == 'list' and self:tmp('n')
  E:stmt(c.line)
  E:w('do local ' .. acc .. (n and (', ' .. n .. ' = {}, 0') or ' = {}'))
  self:push_scope()

  local closes = 0
  for _, clause in ipairs(c.clauses) do
    E:sp(clause.line)
    if clause.k == 'when' then
      E:w('if ')
      self:expr(clause.cond)
      E:w(' then')
      closes = closes + 1
    else
      closes = closes + self:loop_head(clause)
    end
  end

  if n then
    E:stmt(c.expr.line)
    E:w(format('%s = %s + 1; %s[%s] = ', n, n, acc, n))
    self:expr(c.expr)
  elseif c.vexpr then
    E:stmt(c.kexpr.line)
    E:w(acc .. '[')
    self:expr(c.kexpr)
    E:w('] = ')
    self:expr(c.vexpr)
  else
    -- a single expression gives both the key and the value
    local k, v = self:tmp('k'), self:tmp('v')
    E:stmt(c.kexpr.line)
    E:w('local ' .. k .. ', ' .. v .. ' = ')
    self:expr(c.kexpr)
    E:w(format('; %s[%s] = %s', acc, k, v))
  end

  for _ = 1, closes do
    E:sp()
    E:w('end')
  end
  self:pop_scope()
  self:apply(sink, { raw(acc) })
  E:sp()
  E:w('end')
end

-- A value block inside an expression, as an immediately called function.
function Compiler:iife(e)
  local E = self.E
  local vararg = self.fn.vararg
  E:w(vararg and '(function(...)' or '(function()')
  local saved = self.fn
  self.fn = { vararg = vararg, iife = true }
  self:push_scope()
  self:lower(e, { k = 'return' })
  self:pop_scope()
  self.fn = saved
  E:sp()
  E:w(vararg and 'end)(...)' or 'end)()')
end

-- Statements

function Compiler:stmt_ExprStmt(s)
  if #s.exprs > 1 then
    self:error('a list of values can only be the last statement of a function, which returns it', s.exprs[2])
  end
  local e = s.exprs[1]
  if value_blocks[e.k] then
    return self:lower(e, DISCARD)
  end
  if not calls[e.k] then
    self:error('this expression does nothing; only calls can be statements', e)
  end
  self.E:stmt(s.line)
  self:expr(e)
end

function Compiler:stmt_Assign(s)
  local E = self.E
  for _, t in ipairs(s.targets) do
    if t.k == 'Pattern' then return self:destructure(s) end
  end

  local fresh, seen = {}, {}
  local all_fresh = true
  for _, t in ipairs(s.targets) do
    if t.k == 'Name' then
      self:check_name(t.v, t)
      if self.scope:is_fresh(t.v) and not seen[t.v] then
        fresh[#fresh + 1] = t.v
        seen[t.v] = true
      else
        all_fresh = false
      end
    else
      all_fresh = false
    end
  end

  local values = s.values
  E:stmt(s.line)

  if #values == 1 and value_blocks[values[1].k] then
    local names = {}
    for _, name in ipairs(fresh) do names[name] = true end
    if #fresh > 0 then
      E:w('local ' .. concat(fresh, ', '))
    end

    if #fresh > 0 and mentions(values[1], names) then
      -- the block mentions a name being declared, which it mustn't see as the
      -- new local, so it assigns to temporaries first
      local tmps, sink_targets = {}, {}
      for i = 1, #s.targets do
        tmps[i] = self:tmp('value')
        sink_targets[i] = raw(tmps[i])
      end
      E:w(' do local ' .. concat(tmps, ', '))
      self:lower(values[1], { k = 'assign', targets = sink_targets, fresh = true })
      E:w('; ')
      self:targets(s.targets)
      E:w(' = ' .. concat(tmps, ', ') .. ' end')
    else
      self:lower(values[1], { k = 'assign', targets = s.targets, fresh = all_fresh })
    end
    self:declare_all(fresh, s.line)
    return
  end

  if all_fresh then
    E:w('local ')
  elseif #fresh > 0 then
    E:w('local ' .. concat(fresh, ', ') .. '; ')
  end
  self:targets(s.targets)
  E:w(' = ')
  self:expr_list(values)
  -- names are visible after the statement, not in its own right-hand side
  self:declare_all(fresh, s.line)
end

function Compiler:targets(list)
  for i, t in ipairs(list) do
    if i > 1 then self.E:w(', ') end
    self:expr(t)
  end
end

-- Collects what a pattern assigns as { target, value } pairs, with values reading
-- from `base`.
function Compiler:collect_leaves(pattern, base, out)
  local pos = 0
  for _, entry in ipairs(pattern.entries) do
    local access
    if entry.k == 'pos' then
      pos = pos + 1
      access = { k = 'Index', obj = base, key = { k = 'Number', v = tostring(pos) } }
    elseif entry.k == 'named' then
      access = { k = 'Field', obj = base, name = entry.key }
    else
      access = { k = 'Index', obj = base, key = entry.key }
    end
    if entry.target.k == 'Pattern' then
      self:collect_leaves(entry.target, access, out)
    else
      out[#out + 1] = { target = entry.target, value = access }
    end
  end
  return out
end

-- Declares the names in a pattern as new locals, for parameters and loop
-- variables, and assigns them from `base`.
function Compiler:bind_pattern(pattern, base, what)
  local E = self.E
  local leaves = self:collect_leaves(pattern, base, {})
  local names = {}
  for i, leaf in ipairs(leaves) do
    if leaf.target.k ~= 'Name' then
      self:error('only names can be bound by a ' .. what, leaf.target)
    end
    names[i] = leaf.target.v
  end
  E:stmt()
  E:w('local ' .. concat(names, ', ') .. ' = ')
  for i, leaf in ipairs(leaves) do
    if i > 1 then E:w(', ') end
    self:expr(leaf.value)
  end
  for i, leaf in ipairs(leaves) do
    self:bind(names[i], leaf.target, what)
  end
end

function Compiler:destructure(s)
  local E = self.E
  local targets, values = s.targets, s.values
  local fresh, seen = {}, {}
  local all_fresh = true

  local function note(t)
    if t.k == 'Name' then
      self:check_name(t.v, t)
      if self.scope:is_fresh(t.v) and not seen[t.v] then
        fresh[#fresh + 1] = t.v
        seen[t.v] = true
        return
      end
    end
    all_fresh = false
  end

  E:stmt(s.line)

  -- a single pattern taking apart a plain lookup reads from it directly
  if #targets == 1 and #values == 1 and is_path(values[1]) then
    local leaves = self:collect_leaves(targets[1], values[1], {})
    for _, leaf in ipairs(leaves) do note(leaf.target) end
    if all_fresh then
      E:w('local ')
    elseif #fresh > 0 then
      E:w('local ' .. concat(fresh, ', ') .. '; ')
    end
    for i, leaf in ipairs(leaves) do
      if i > 1 then E:w(', ') end
      self:expr(leaf.target)
    end
    E:w(' = ')
    for i, leaf in ipairs(leaves) do
      if i > 1 then E:w(', ') end
      self:expr(leaf.value)
    end
    self:declare_all(fresh, s.line)
    return
  end

  -- otherwise the values are evaluated into temporaries first
  local lua_targets, leaves, tmps = {}, {}, {}
  for i, t in ipairs(targets) do
    if t.k == 'Pattern' then
      local tmp = self:tmp('obj')
      tmps[#tmps + 1] = tmp
      lua_targets[i] = raw(tmp)
      self:collect_leaves(t, raw(tmp), leaves)
    else
      lua_targets[i] = t
      note(t)
    end
  end
  for _, leaf in ipairs(leaves) do note(leaf.target) end

  if #fresh > 0 then
    E:w('local ' .. concat(fresh, ', ') .. '; ')
  end
  if #targets == 1 then
    E:w('do local ' .. tmps[1] .. ' = ')
  else
    E:w('do local ' .. concat(tmps, ', ') .. '; ')
    self:targets(lua_targets)
    E:w(' = ')
  end
  self:expr_list(values)
  E:w('; ')
  for i, leaf in ipairs(leaves) do
    if i > 1 then E:w(', ') end
    self:expr(leaf.target)
  end
  E:w(' = ')
  for i, leaf in ipairs(leaves) do
    if i > 1 then E:w(', ') end
    self:expr(leaf.value)
  end
  E:w(' end')
  self:declare_all(fresh, s.line)
end

function Compiler:stmt_Update(s)
  local E = self.E
  local target = s.target
  E:stmt(s.line)

  -- receivers and keys with side effects are evaluated once
  local names, values = {}, {}
  local function once(e)
    if is_simple(e) then return e end
    local name = self:tmp('ref')
    names[#names + 1] = name
    values[#values + 1] = e
    return raw(name)
  end

  local t = target
  if target.k == 'Name' then
    self:check_name(target.v, target)
  elseif target.k == 'Field' and target.obj.k ~= 'Super' then
    t = { k = 'Field', obj = once(target.obj), name = target.name, line = target.line }
  elseif target.k == 'Index' then
    t = { k = 'Index', obj = once(target.obj), key = once(target.key), line = target.line }
  end

  if #names > 0 then
    E:w('do local ' .. concat(names, ', ') .. ' = ')
    self:expr_list(values)
    E:w('; ')
  end
  self:expr(t)
  E:w(' = ')
  self:expr({ k = 'Binop', op = s.op, l = t, r = s.value })
  if #names > 0 then E:w(' end') end
end

function Compiler:stmt_Return(s, wrap)
  local E = self.E
  if self.fn.iife then
    self:error("'return' can't be used here, as the expression it's in is compiled to a function; assign the expression to a variable first", s)
  end
  local values = s.values
  if #values == 1 and value_blocks[values[1].k] then
    return self:lower(values[1], { k = 'return' })
  end
  E:stmt(s.line)
  E:w(wrap and 'do return' or 'return')
  if #values > 0 then
    E:w(' ')
    self:expr_list(values)
  end
  if wrap then E:w(' end') end
end

function Compiler:loop_for(s, what)
  local loop = self.fn.loop
  if not loop then
    if self.fn.iife then
      self:error(format(
        "'%s' can't be used here, as the expression it's in is compiled to a function; assign the expression to a variable first",
        what), s)
    end
    self:error(format("'%s' outside of a loop", what), s)
  end
  return loop
end

function Compiler:stmt_Break(s, wrap)
  self:loop_for(s, 'break')
  self.E:stmt(s.line)
  self.E:w(wrap and 'do break end' or 'break')
end

function Compiler:stmt_Continue(s)
  local loop = self:loop_for(s, 'continue')
  self.E:stmt(s.line)
  self.E:w('goto ' .. loop.label)
end

function Compiler:stmt_Local(s)
  local E = self.E
  local names = {}
  for i, n in ipairs(s.names) do
    self:check_name(n.v, n)
    names[i] = n.v
  end
  E:stmt(s.line)
  E:w('local ' .. concat(names, ', '))
  if s.values then
    E:w(' = ')
    self:expr_list(s.values)
  end
  self:declare_all(names, s.line)
end

function Compiler:stmt_Export(s)
  if s.all then
    self.scope.export_all = true
    return
  end
  if s.class then
    self.scope.exported[s.class.name] = true
    return self:stmt_Class(s.class)
  end

  local names = {}
  for i, n in ipairs(s.names) do
    self:check_name(n.v, n)
    self.scope.exported[n.v] = true
    names[i] = n.v
  end
  if s.values then
    self.E:stmt(s.line)
    self.E:w(concat(names, ', ') .. ' = ')
    self:expr_list(s.values)
  end
end

function Compiler:stmt_Import(s)
  local entries = {}
  for i, n in ipairs(s.names) do
    entries[i] = { k = 'named', key = n.v, target = { k = 'Name', v = n.v, line = n.line, col = n.col } }
  end
  self:destructure({
    targets = { { k = 'Pattern', entries = entries } },
    values = { s.from },
    line = s.line,
  })
end

function Compiler:stmt_If(s) self:lower_if(s, DISCARD) end
function Compiler:stmt_Switch(s) self:lower_switch(s, DISCARD) end
function Compiler:stmt_With(s) self:lower_with(s, DISCARD) end
function Compiler:stmt_Do(s) self:lower_do(s, DISCARD) end
function Compiler:stmt_For(s) self:loop(s) end
function Compiler:stmt_ForIn(s) self:loop(s) end
function Compiler:stmt_While(s) self:loop(s) end

-- Assigned names in a class body are locals of the class body, declared up front
-- so that every method sees them.
local function class_locals(body, scope)
  local names, seen = {}, {}
  local function add(t)
    if t.k == 'Name' and not seen[t.v] and scope:is_fresh(t.v) then
      names[#names + 1] = t.v
      seen[t.v] = true
    elseif t.k == 'Pattern' then
      for _, entry in ipairs(t.entries) do add(entry.target) end
    end
  end
  for _, item in ipairs(body) do
    if item.k == 'Assign' then
      for _, t in ipairs(item.targets) do add(t) end
    end
  end
  return names
end

-- Classes are laid out exactly as MoonScript lays them out, so that the two can
-- extend each other. Unlike MoonScript, the body runs top to bottom, which keeps
-- the lines aligned; since the base may then already have a parent with a
-- __newindex, members are added with rawset.
function Compiler:stmt_Class(s)
  local E = self.E
  local name = s.name
  self:check_name(name, s.name_tok)
  local c, b = self:tmp('class'), self:tmp('base')
  local p = s.parent and self:tmp('parent')

  E:stmt(s.line)
  if self.scope:is_fresh(name) then
    E:w('local ' .. name .. '; ')
    self.scope:declare(name, s.line)
  end
  E:w(format('do local %s; local %s = {}; %s.__index = %s', c, b, b, b))
  if p then
    E:w('; local ' .. p .. ' = ')
    self:expr(s.parent)
  end

  self:push_scope()
  local locals = class_locals(s.body, self.scope)
  if #locals > 0 then
    E:w('; local ' .. concat(locals, ', '))
    self:declare_all(locals, s.line)
  end

  local init = p and format('function(self, ...) return %s.__parent.__init(self, ...) end', c)
    or 'function() end'
  local index = p and format(
    'function(cls, name) local val = rawget(%s, name); if val == nil then local parent = rawget(cls, "__parent"); if parent then return parent[name] end else return val end end',
    b) or b
  E:w(format(
    '; %s = setmetatable({__init = %s, __base = %s, __name = %q%s}, {__index = %s, __call = function(cls, ...) local self = setmetatable({}, %s); cls.__init(self, ...); return self end}); %s.__class = %s',
    c, init, b, name, p and (', __parent = ' .. p) or '', index, b, b, c))
  if p then
    E:w(format('; setmetatable(%s, %s.__base)', b, p))
  end
  E:w('; local self = ' .. c)
  self.scope:declare('self', s.line)

  local saved_cls = self.cls
  self.cls = { c = c, b = b, p = p }

  for _, item in ipairs(s.body) do
    if item.k == 'prop' then
      E:stmt(item.line)
      local is_new = item.key == 'new'
      if is_new then
        E:w(c .. '.__init = ')
      elseif type(item.key) == 'string' then
        E:w(p and format('rawset(%s, %q, ', b, item.key) or (b .. field(item.key) .. ' = '))
      else
        E:w(p and ('rawset(' .. b .. ', ') or (b .. '['))
        self:expr(item.key)
        E:w(p and ', ' or '] = ')
      end
      self.cls.method = type(item.key) == 'string' and item.key or nil
      if item.value.k == 'Func' then
        -- constructors return nothing
        self:func(item.value, is_new)
      else
        self:expr(item.value)
      end
      self.cls.method = nil
      if p and not is_new then E:w(')') end
    elseif item.k == 'classvar' then
      E:stmt(item.line)
      E:w(c .. field(item.key) .. ' = ')
      self:expr(item.value)
    else
      self:stmt(item)
    end
  end

  self.cls = saved_cls
  self:pop_scope()
  if p then
    E:w(format(' if %s.__inherited then %s.__inherited(%s, %s) end', p, p, p, c))
  end
  E:sp()
  E:w(name .. ' = ' .. c .. ' end')
end

-- Expressions

function Compiler:expr(e, min)
  self.E:at(e.line)
  local handler = expr_handlers[e.k]
  if handler then
    return handler(self, e, min or 0)
  end
  if value_blocks[e.k] then
    return self:iife(e)
  end
  self:error('unexpected ' .. e.k, e)
end

function Compiler:expr_list(list)
  for i, e in ipairs(list) do
    if i > 1 then self.E:w(', ') end
    self:expr(e)
  end
end

-- An expression used as the receiver of a call, index or field access.
function Compiler:prefix(e)
  if prefix_kinds[e.k] then
    return self:expr(e)
  end
  self.E:at(e.line)
  self.E:w('(')
  self:expr(e)
  self.E:w(')')
end

function Compiler:e_Nil() self.E:w('nil') end
function Compiler:e_True() self.E:w('true') end
function Compiler:e_False() self.E:w('false') end
function Compiler:e_Number(e) self.E:w(e.v) end
function Compiler:e_Raw(e) self.E:w(e.code) end

function Compiler:e_Vararg(e)
  if not self.fn.vararg then
    self:error("'...' can only be used in a function taking '...'", e)
  end
  self.E:w('...')
end

function Compiler:e_Name(e)
  self:check_name(e.v, e)
  self.E:w(e.v)
end

function Compiler:e_Self(e)
  self:need_self(e)
  self.E:w('self')
end

function Compiler:e_SelfField(e)
  self:need_self(e)
  self.E:w('self' .. field(e.name))
end

function Compiler:e_ClassRef(e)
  self:need_self(e)
  self.E:w('self.__class')
end

function Compiler:e_ClassField(e)
  self:need_self(e)
  self.E:w('self.__class' .. field(e.name))
end

function Compiler:e_WithField(e)
  self.E:w(self:with_var(e) .. field(e.name))
end

function Compiler:e_WithCall(e)
  self:invoke(raw(self:with_var(e)), e.name, e.args)
end

function Compiler:e_Super(e)
  self.E:w(self:super_cls(e).c .. '.__parent')
end

function Compiler:e_Field(e)
  self:prefix(e.obj)
  self.E:w(field(e.name))
end

function Compiler:e_Index(e)
  self:prefix(e.obj)
  self.E:w('[')
  self:expr(e.key)
  self.E:w(']')
end

function Compiler:e_Slice(e)
  self:error("slices can only be used in loops, as in 'for x in *t[2,]'", e)
end

function Compiler:e_Paren(e)
  self.E:w('(')
  self:expr(e.e)
  self.E:w(')')
end

function Compiler:args(args, first)
  local E = self.E
  E:w('(')
  if first then
    E:w(first)
    if #args > 0 then E:w(', ') end
  end
  self:expr_list(args)
  E:w(')')
end

-- obj:name(args), also when name is a Lua keyword.
function Compiler:invoke(obj, name, args)
  local E = self.E
  if valid_name(name) then
    self:prefix(obj)
    E:w(':' .. name)
    self:args(args)
  elseif obj.k == 'Name' or obj.k == 'Self' or (obj.k == 'Raw' and match(obj.code, '^[%a_][%w_]*$')) then
    self:expr(obj)
    E:w(field(name))
    E:w('(')
    self:expr(obj)
    if #args > 0 then E:w(', ') end
    self:expr_list(args)
    E:w(')')
  else
    -- the receiver can't be evaluated twice
    self.needs_invoke = true
    E:w('__hs_invoke(')
    self:expr(obj)
    E:w(', ' .. format('%q', name))
    if #args > 0 then E:w(', ') end
    self:expr_list(args)
    E:w(')')
  end
end

function Compiler:e_Call(e)
  local fn = e.fn
  local E = self.E
  if fn.k == 'SelfField' then
    -- @m(...) is a method call on self
    self:need_self(fn)
    self:invoke(raw('self'), fn.name, e.args)
  elseif fn.k == 'ClassField' then
    self:need_self(fn)
    self:invoke(raw('self.__class'), fn.name, e.args)
  elseif fn.k == 'Super' then
    local cls = self:super_cls(fn, true)
    self:need_self(fn)
    if cls.method == 'new' then
      E:w(cls.c .. '.__parent.__init')
    else
      E:w(cls.c .. '.__parent.__base' .. field(cls.method))
    end
    self:args(e.args, 'self')
  else
    self:prefix(fn)
    self:args(e.args)
  end
end

function Compiler:e_MethodCall(e)
  if e.obj.k == 'Super' then
    local cls = self:super_cls(e.obj)
    self:need_self(e.obj)
    self.E:w(cls.c .. '.__parent' .. field(e.name))
    return self:args(e.args, 'self')
  end
  self:invoke(e.obj, e.name, e.args)
end

function Compiler:e_Unop(e, min)
  local E = self.E
  local paren = UNARY < min
  if paren then E:w('(') end
  if e.op == 'not' then
    E:w('not ')
  elseif e.op == '-' and e.e.k == 'Unop' and e.e.op == '-' then
    E:w('- ') -- '--' would start a comment
  else
    E:w(e.op)
  end
  self:expr(e.e, UNARY)
  if paren then E:w(')') end
end

function Compiler:e_Binop(e, min)
  local E = self.E
  local op = e.op == '!=' and '~=' or e.op
  local p = precedence[op]
  local paren = p < min
  if paren then E:w('(') end
  local lmin, rmin = p, p + 1
  if op == '..' or op == '^' then
    lmin, rmin = p + 1, p
  end
  self:expr(e.l, lmin)
  E:w(' ' .. op .. ' ')
  self:expr(e.r, rmin)
  if paren then E:w(')') end
end

function Compiler:e_String(e, min)
  local E = self.E
  local parts, q = e.parts, e.q
  if q == '[' then return E:w(parts[1]) end
  if #parts == 0 then return E:w(q .. q) end
  if #parts == 1 and type(parts[1]) == 'string' then
    return E:w(q .. parts[1] .. q)
  end

  local paren = #parts > 1 and precedence['..'] < min
  if paren then E:w('(') end
  for i, part in ipairs(parts) do
    if i > 1 then E:w(' .. ') end
    if type(part) == 'string' then
      E:w(q .. part .. q)
    else
      E:w('tostring(')
      self:expr(part)
      E:w(')')
    end
  end
  if paren then E:w(')') end
end

function Compiler:e_Table(e)
  local E = self.E
  E:w('{')
  for i, entry in ipairs(e.entries) do
    if i > 1 then E:w(', ') end
    E:at(entry.line)
    if entry.k == 'pos' then
      self:expr(entry.v)
    elseif entry.k == 'named' then
      E:w(key(entry.key) .. ' = ')
      self:expr(entry.v)
    else
      E:w('[')
      self:expr(entry.key)
      E:w('] = ')
      self:expr(entry.v)
    end
  end
  E:w('}')
end

function Compiler:e_Func(e)
  self:func(e)
end

-- Emits a function. Parameters are handled in the order they're written: defaults,
-- assignments to self for @x parameters, and destructuring.
function Compiler:func(e, no_return)
  local E = self.E
  local names = {}
  local vararg = false
  if e.fat then names[1] = 'self' end
  for _, p in ipairs(e.params) do
    if p.vararg then
      vararg = true
      names[#names + 1] = '...'
    elseif p.pattern then
      p.lua_name = self:tmp('arg')
      names[#names + 1] = p.lua_name
    else
      names[#names + 1] = p.name
    end
    if p.self_assign and not e.fat then
      self:error("an @ parameter needs a method, defined with '=>'", p.tok)
    end
  end

  E:w('function(' .. concat(names, ', ') .. ')')
  local saved_fn = self.fn
  self.fn = { vararg = vararg }
  self:push_scope()
  if e.fat then self.scope:declare('self', e.line) end
  for _, p in ipairs(e.params) do
    if p.name then self:bind(p.name, p.tok, 'parameter') end
  end

  for _, p in ipairs(e.params) do
    local name = p.name or p.lua_name
    if p.default then
      E:stmt()
      E:w('if ' .. name .. ' == nil then ' .. name .. ' = ')
      self:expr(p.default)
      E:w(' end')
    end
    if p.self_assign then
      E:stmt()
      E:w('self' .. field(p.name) .. ' = ' .. p.name)
    end
    if p.pattern then
      self:bind_pattern(p.pattern, raw(p.lua_name), 'parameter')
    end
  end

  self:block(e.body, not no_return and IMPLICIT_RETURN or nil)
  self:pop_scope()
  self.fn = saved_fn
  E:sp()
  E:w('end')
end

for name, method in pairs(Compiler) do
  local kind = match(name, '^stmt_(%u%w*)$')
  if kind then stmt_handlers[kind] = method end
  kind = match(name, '^e_(%u%w*)$')
  if kind then expr_handlers[kind] = method end
end

local function compile(stmts, source)
  local c = new(source)
  c.fn = { vararg = true }
  c.scope = Scope.new(nil)
  c:block(stmts, IMPLICIT_RETURN)
  local lua = c.E:result()
  if c.needs_invoke then
    lua = 'local function __hs_invoke(o, k, ...) return o[k](o, ...) end ' .. lua
  end
  return lua
end

return {
  compile = compile,
}
