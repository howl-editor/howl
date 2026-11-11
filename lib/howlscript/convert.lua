-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Converts MoonScript to Howlscript, following the rules in CONVERTING.md.
--
-- The MoonScript is parsed with MoonScript's own grammar, instrumented to record
-- the span of source each node covers. The Howlscript is then rendered from that
-- tree, copying the source between and around the nodes, so comments, blank lines
-- and layout stay as they were except where a rule changes them. What the rules
-- don't cover is left as it is and reported as a warning, or left for the
-- Howlscript compiler to reject.

local lpeg = require('lpeg')

local concat, insert, sort = table.concat, table.insert, table.sort
local sub, find, match, gsub, rep, byte =
  string.sub, string.find, string.match, string.gsub, string.rep, string.byte

local function pack(...) return { n = select('#', ...), ... } end

-------------------------------------------------------------------------------
-- Parsing
-------------------------------------------------------------------------------

-- MoonScript's grammar is loaded privately with its function and table captures
-- wrapped to record the span of source they cover, kept in a side table as
-- { start, stop }, where stop is exclusive and both can take in whitespace.
local raw_spans = setmetatable({}, { __mode = 'k' })

-- Plain lists from table captures, such as parameter lists, whose first entry
-- can be a string without naming a node kind: a parameter called `table` is
-- { 'table' }. A list that a function capture returns, as flatten_or_mark does
-- after adding a kind, is a node.
local raw_lists = setmetatable({}, { __mode = 'k' })

local function record(v, s, e)
  if type(v) ~= 'table' then return end
  local span = raw_spans[v]
  if span then
    -- a node a capture returns again, extended as join_chain does, covers both
    if s < span[1] then span[1] = s end
    if e > span[2] then span[2] = e end
  else
    raw_spans[v] = { s, e }
  end
end

local build_grammar

local function load_grammar()
  local path = assert(package.searchpath('moonscript.parse', package.path))
  local mt = getmetatable(lpeg.P(1))
  local orig_div, orig_ct = mt.__div, lpeg.Ct
  local Cp, C = lpeg.Cp, lpeg.C

  local function spanned(f)
    return function(...)
      local n = select('#', ...)
      local args = { ... }
      local res
      if n == 3 then
        res = pack(f(args[2])) -- no captures of its own: f gets the match
      else
        res = pack(f(unpack(args, 3, n - 1)))
      end
      for i = 1, res.n do
        record(res[i], args[1], args[n])
        if type(res[i]) == 'table' then raw_lists[res[i]] = nil end
      end
      return unpack(res, 1, res.n)
    end
  end

  local function div(a, b)
    if type(b) == 'function' then
      return orig_div(Cp() * C(a) * Cp(), spanned(b))
    end
    return orig_div(a, b)
  end

  local function ct(p)
    return orig_div(Cp() * orig_ct(p) * Cp(), function(s, t, e)
      record(t, s, e)
      raw_lists[t] = true
      return t
    end)
  end

  -- the grammar module takes Ct when it loads, and builds its patterns, and so
  -- uses `/`, each time a grammar is built
  lpeg.Ct = ct
  local ok, mod = pcall(function() return assert(loadfile(path))() end)
  lpeg.Ct = orig_ct
  if not ok then error(mod, 0) end

  build_grammar = function()
    mt.__div = div
    local ok2, g, state = pcall(mod.build_grammar)
    mt.__div = orig_div
    if not ok2 then error(g, 0) end
    return g, state
  end
end

-- Classifies each byte of the source: 'w' for whitespace, 'c' for comments and
-- 's' for strings, and 'x' for other code, which includes interpolated code.
local function classify(src)
  local kinds = {}
  local n = #src
  local scan_code

  -- scans the string opening at i, returning the position after it
  local function scan_string(i, quote)
    kinds[i] = 's'
    i = i + 1
    while i <= n do
      local c = byte(src, i)
      if c == 92 then -- \
        kinds[i], kinds[i + 1] = 's', 's'
        i = i + 2
      elseif c == quote then
        kinds[i] = 's'
        return i + 1
      elseif quote == 34 and c == 35 and byte(src, i + 1) == 123 then -- #{
        kinds[i], kinds[i + 1] = 's', 's'
        local close = scan_code(i + 2, true)
        kinds[close] = 's'
        i = close + 1
      else
        kinds[i] = 's'
        i = i + 1
      end
    end
    return i
  end

  -- scans code from i, to the end or, in an interpolation, to its closing brace,
  -- whose position it returns
  scan_code = function(i, interpolation)
    local depth = 0
    while i <= n do
      local c = byte(src, i)
      if c == 32 or c == 9 or c == 10 or c == 13 then
        kinds[i] = 'w'
        i = i + 1
      elseif c == 45 and byte(src, i + 1) == 45 then -- --
        local stop = find(src, '\n', i, true) or n + 1
        for j = i, stop - 1 do kinds[j] = 'c' end
        i = stop
      elseif c == 39 or c == 34 then -- ' "
        i = scan_string(i, c)
      elseif c == 91 and match(src, '^%[=*%[', i) then
        local open = match(src, '^%[=*%[', i)
        local close = ']' .. rep('=', #open - 2) .. ']'
        local _, stop = find(src, close, i + #open, true)
        stop = stop or n
        for j = i, stop do kinds[j] = 's' end
        i = stop + 1
      elseif interpolation and c == 125 and depth == 0 then -- }
        return i
      else
        if c == 123 then
          depth = depth + 1
        elseif c == 125 then
          depth = depth - 1
        end
        kinds[i] = 'x'
        i = i + 1
      end
    end
    return n
  end

  scan_code(1, false)
  return kinds
end

-- Parses MoonScript source. Returns the tree, a table mapping nodes to
-- { first, last }, the positions of the first and last bytes of code they cover,
-- the byte kinds from classify(), and the set of plain lists (see raw_lists).
local function parse(src)
  if not build_grammar then load_grammar() end
  local literals = require('moonscript.parse.literals')
  local util = require('moonscript.util')
  local g, state = build_grammar()
  local file_grammar = literals.White * g * literals.White * -1
  local ok, tree = pcall(function() return file_grammar:match(src) end)
  if not ok then
    if type(tree) == 'table' and tree[2] then
      local line = util.pos_to_line(src, tree[1][-1] or 1)
      error(('line %d: %s'):format(line, tree[2]), 0)
    end
    error(tree, 0)
  end
  if not tree then
    error(('line %d: failed to parse'):format(util.pos_to_line(src, state.last_pos)), 0)
  end

  local kinds = classify(src)
  local spans, lists = {}, {}
  local seen = {}
  local function walk(node)
    if seen[node] then return end
    seen[node] = true
    if raw_lists[node] then lists[node] = true end
    local raw = raw_spans[node]
    if raw then
      local first, last = raw[1], raw[2] - 1
      while first <= last and (kinds[first] == 'w' or kinds[first] == 'c') do
        first = first + 1
      end
      while last >= first and (kinds[last] == 'w' or kinds[last] == 'c') do
        last = last - 1
      end
      if first <= last then spans[node] = { first, last } end
    end
    for k, v in pairs(node) do
      if type(v) == 'table' and k ~= -1 then walk(v) end
    end
  end
  walk(tree)
  return tree, spans, kinds, lists
end

-------------------------------------------------------------------------------
-- Scopes
-------------------------------------------------------------------------------

-- Finds the names each assignment declares, following MoonScript's scoping: a
-- name assigned that isn't visible is a new local of the enclosing block.
local function find_new_names(tree, lists)
  local new_names, nil_names = {}, {}

  local function visible(scope, name)
    while scope do
      if scope.names[name] then return true end
      scope = scope.parent
    end
    return false
  end

  local function child(scope) return { names = {}, parent = scope } end

  local walk, walk_block

  -- Assigns to the names in a target. A name that isn't visible is declared,
  -- and goes in `set`. A name declared with a bare `local` in the same block and
  -- not assigned since is surely nil, and goes in `nils`.
  local function declare_pattern(pat, scope, set, nils)
    if type(pat) == 'string' then
      local owner = scope
      while owner and not owner.names[pat] do owner = owner.parent end
      if not owner then
        scope.names[pat] = true
        if set then set[pat] = true end
      else
        if owner == scope and owner.names[pat] == 'declared' and nils then
          nils[pat] = true
        end
        owner.names[pat] = true
      end
    elseif type(pat) == 'table' then
      if pat[1] == 'ref' then
        declare_pattern(pat[2], scope, set, nils)
      elseif pat[1] == 'table' then
        for _, entry in ipairs(pat[2]) do
          local target = entry[2] or entry[1]
          if type(target) == 'table' and target[1] == 'ref' then
            declare_pattern(target[2], scope, set)
          elseif type(target) == 'table' and target[1] == 'table' then
            declare_pattern(target, scope, set)
          end
        end
      end
    end
  end

  local function walk_children(node, scope)
    for k, v in pairs(node) do
      if type(k) == 'number' and k > 0 and type(v) == 'table' then
        walk(v, scope)
      end
    end
  end

  local function walk_clauses(clauses, scope)
    for _, clause in ipairs(clauses) do
      if clause[1] == 'foreach' then
        walk_children(clause[3], scope)
        for _, name in ipairs(clause[2]) do declare_pattern(name, scope) end
      elseif clause[1] == 'for' then
        walk_children(clause[3], scope)
        scope.names[clause[2]] = true
      elseif clause[1] == 'when' then
        walk(clause[2], scope)
      end
    end
  end

  walk = function(node, scope)
    local kind = not lists[node] and node[1]
    if kind == 'fndef' then
      local inner = child(scope)
      for _, param in ipairs(node[2]) do
        if type(param[1]) == 'string' then inner.names[param[1]] = true end
        if param[2] then walk(param[2], inner) end
      end
      if type(node[5]) == 'table' then walk_block(node[5], inner) end
    elseif kind == 'assign' then
      walk_children(node[3], scope)
      local set, nils = {}, {}
      for _, target in ipairs(node[2]) do declare_pattern(target, scope, set, nils) end
      new_names[node] = set
      nil_names[node] = nils
    elseif kind == 'update' then
      walk(node[4], scope)
      declare_pattern(node[2], scope)
    elseif kind == 'declare_with_shadows' then
      for _, name in ipairs(node[2]) do scope.names[name] = 'declared' end
    elseif kind == 'import' then
      walk(node[3], scope)
      for _, name in ipairs(node[2]) do
        if type(name) == 'string' then
          scope.names[name] = true
        else
          scope.names[name[2]] = true
        end
      end
    elseif kind == 'export' then
      if type(node[2]) == 'table' then
        for _, name in ipairs(node[2]) do
          if type(name) == 'string' then scope.names[name] = true end
        end
      end
      walk_children(node, scope)
    elseif kind == 'class' then
      if type(node[2]) == 'table' then declare_pattern(node[2], scope) end
      if type(node[3]) == 'table' then walk(node[3], scope) end
      local inner = child(scope)
      for _, line in ipairs(node[4] or {}) do
        if line[1] == 'stm' then
          walk(line[2], inner)
        else
          walk_children(line, inner)
        end
      end
    elseif kind == 'if' or kind == 'unless' then
      walk(node[2], scope)
      walk_block(node[3], child(scope))
      for i = 4, #node do
        local branch = node[i]
        if branch[1] == 'elseif' then
          walk(branch[2], scope)
          walk_block(branch[3], child(scope))
        else
          walk_block(branch[2], child(scope))
        end
      end
    elseif kind == 'switch' then
      walk(node[2], scope)
      for _, case in ipairs(node[3]) do
        if case[1] == 'case' then
          walk_children(case[2], scope)
          walk_block(case[3], child(scope))
        else
          walk_block(case[2], child(scope))
        end
      end
    elseif kind == 'while' or kind == 'with' then
      walk(node[2], scope)
      walk_block(node[3], child(scope))
    elseif kind == 'do' then
      walk_block(node[2], child(scope))
    elseif kind == 'for' and node[4] then
      walk_children(node[3], scope)
      local inner = child(scope)
      inner.names[node[2]] = true
      walk_block(node[4], inner)
    elseif kind == 'foreach' and node[4] then
      walk_children(node[3], scope)
      local inner = child(scope)
      for _, name in ipairs(node[2]) do declare_pattern(name, inner) end
      walk_block(node[4], inner)
    elseif kind == 'comprehension' or kind == 'tblcomprehension' then
      local inner = child(scope)
      walk_clauses(node[3], inner)
      walk_children(node[2], inner)
    elseif kind == 'decorated' then
      local decorator = node[3]
      if decorator[1] == 'comprehension' then
        local inner = child(scope)
        walk_clauses(decorator[2], inner)
        walk(node[2], inner)
      else
        walk_children(decorator, scope)
        walk(node[2], scope)
      end
    elseif type(kind) == 'string' then
      walk_children(node, scope)
    else
      walk_children(node, scope)
    end
  end

  walk_block = function(block, scope)
    if type(block) ~= 'table' then return end
    for _, stmt in ipairs(block) do
      if type(stmt) == 'table' then walk(stmt, scope) end
    end
  end

  walk_block(tree, { names = {} })
  return new_names, nil_names
end

-------------------------------------------------------------------------------
-- Rendering
-------------------------------------------------------------------------------

-- Markers in rendered text, resolved at the end:
-- GLUE starts a table whose '{' goes after the code before it, on its line,
-- and GLUE_ARG one that's an argument, which may need a comma before it;
-- CLOSE starts a line holding closing brackets, before which a comment ending
-- the line above is moved.
local GLUE, GLUE_ARG, CLOSE = '\3', '\4', '\1'

local DROP = {}

local BUSTED = {
  describe = true, context = true, it = true, spec = true, test = true,
  before_each = true, after_each = true, setup = true, teardown = true,
  pending = true, insulate = true, expose = true, finally = true,
  lazy_setup = true, lazy_teardown = true, strict_setup = true,
  strict_teardown = true,
}

local METAMETHODS = {
  __tostring = true, __eq = true, __lt = true, __le = true, __len = true,
  __concat = true, __call = true, __unm = true, __add = true, __sub = true,
  __mul = true, __div = true, __mod = true, __pow = true, __pairs = true,
  __ipairs = true, __mode = true, __gc = true, __index = true, __newindex = true,
}

local VALUE_KINDS = {
  chain = true, ref = true, self = true, self_class = true, number = true,
  string = true, exp = true, table = true, fndef = true, comprehension = true,
  tblcomprehension = true, parens = true, minus = true, ['not'] = true,
  length = true, explist = true, with = true, bitnot = true,
}

local STMT = { stmt = true }
local VALUE = {}
local LIST = { in_list = true }
local ARG = { in_list = true, arg = true }
local OPERAND = { operand = true }

local Conv = {}
Conv.__index = Conv

local handlers = {}

local function new_converter(src, opts)
  local tree, spans, kinds, lists = parse(src)
  local self = setmetatable({
    src = src,
    tree = tree,
    spans = spans,
    kinds = kinds,
    lists = lists,
    opts = opts or {},
    warnings = {},
    kid_cache = {},
  }, Conv)
  self.new_names, self.nil_names = find_new_names(tree, lists)

  local starts = { 1 }
  for pos in src:gmatch('()\n') do starts[#starts + 1] = pos + 1 end
  self.line_starts = starts
  self:prepare_edits()
  return self
end

function Conv:warn(pos, msg)
  insert(self.warnings, { line = self:line_of(pos), message = msg })
end

function Conv:line_of(pos)
  local starts = self.line_starts
  local lo, hi = 1, #starts
  while lo < hi do
    local mid = math.floor((lo + hi + 1) / 2)
    if starts[mid] <= pos then lo = mid else hi = mid - 1 end
  end
  return lo
end

-- the indentation of the line holding pos, as it will be in the Howlscript
function Conv:indent_at(pos)
  local line = self:line_of(pos)
  local indent = match(self.src, '^[ \t]*', self.line_starts[line])
  local delta = self.line_deltas[line]
  if not delta then return indent end
  if delta > 0 then return indent .. rep(' ', delta) end
  return sub(indent, -delta + 1)
end

-- Source edits, applied wherever the source is copied: text inserted before a
-- byte, and bytes deleted.
function Conv:insert_before(pos, text)
  self.ins[pos] = (self.ins[pos] or '') .. text
end

-- A block indented by other than two spaces moves to two, along with the lines
-- inside it.
function Conv:find_line_deltas()
  local deltas = {}
  local starts = self.line_starts
  local function original_indent(line)
    return #match(self.src, '^[ \t]*', starts[line])
  end
  local function fix(block)
    local span = self.spans[block]
    if not span or not self:starts_line(span[1]) then return end
    local before = self:code_before(span[1])
    if not before then return end
    local step = original_indent(self:line_of(span[1])) - original_indent(self:line_of(before))
    if step > 0 and step ~= 2 then
      for line = self:line_of(span[1]), self:line_of(span[2]) do
        deltas[line] = (deltas[line] or 0) + 2 - step
      end
    end
  end
  local BLOCKS = {
    fndef = 5, ['if'] = 3, unless = 3, ['elseif'] = 3, ['else'] = 2, with = 3,
    ['while'] = 3, ['for'] = 4, foreach = 4, ['do'] = 2, case = 3, class = 4,
  }
  local seen = {}
  local function walk(node)
    if seen[node] then return end
    seen[node] = true
    local kind = not self.lists[node] and node[1]
    local field = BLOCKS[kind]
    if field and type(node[field]) == 'table' then fix(node[field]) end
    if kind == 'table' and self.spans[node] and self:braceless(node) then fix(node) end
    for k, v in pairs(node) do
      if type(k) == 'number' and k > 0 and type(v) == 'table' then walk(v) end
    end
  end
  walk(self.tree)
  return deltas
end

function Conv:prepare_edits()
  local src, kinds = self.src, self.kinds
  self.ins, self.del = {}, {}

  -- a comment touching a name or ']' gets a space, as Howlscript would read the
  -- -- as a decrement
  for i = 2, #src do
    if kinds[i] == 'c' and kinds[i - 1] ~= 'c' and find(sub(src, i - 1, i - 1), '[%w_%]]') then
      self:insert_before(i, ' ')
    end
  end

  -- trailing whitespace goes
  for i = 1, #src do
    local c = byte(src, i)
    if (c == 32 or c == 9) and (kinds[i] == 'w' or kinds[i] == 'c') then
      local j = i
      while byte(src, j) == 32 or byte(src, j) == 9 do j = j + 1 end
      if j > #src or byte(src, j) == 10 or byte(src, j) == 13 then
        for k = i, j - 1 do self.del[k] = true end
      end
    end
  end

  self.line_deltas = {}
  local deltas = self:find_line_deltas()
  for line, delta in pairs(deltas) do
    local start = self.line_starts[line]
    local blank = match(src, '^[ \t]*\r?\n', start) or start > #src
    local in_string = start > 1 and kinds[start - 1] == 's'
    if delta ~= 0 and not blank and not in_string then
      self.line_deltas[line] = delta
      if delta > 0 then
        self:insert_before(start, rep(' ', delta))
      else
        for k = start, start - delta - 1 do
          if byte(src, k) == 32 then self.del[k] = true end
        end
      end
    end
  end
end

function Conv:same_line(a, b)
  return self:line_of(a) == self:line_of(b)
end

-- the position of the last code byte before pos, or nil
function Conv:code_before(pos)
  local kinds = self.kinds
  local i = pos - 1
  while i >= 1 and (kinds[i] == 'w' or kinds[i] == 'c') do i = i - 1 end
  if i >= 1 then return i end
end

-- whether the code before pos ends on an earlier line
function Conv:starts_line(pos)
  local before = self:code_before(pos)
  return not before or not self:same_line(before, pos)
end

-- the source from a to b, with the edits falling in it
function Conv:gap(a, b)
  if b < a then return '' end
  local ins, del = self.ins, self.del
  local out, from = nil, a
  for i = a, b do
    if ins[i] or del[i] then
      out = out or {}
      out[#out + 1] = sub(self.src, from, i - 1)
      if ins[i] then out[#out + 1] = ins[i] end
      from = del[i] and i + 1 or i
    end
  end
  if not out then return sub(self.src, a, b) end
  out[#out + 1] = sub(self.src, from, b)
  return concat(out)
end

-- The nodes with spans directly below a node, through nodes without one, in
-- source order.
function Conv:kids(node)
  local cached = self.kid_cache[node]
  if cached then return cached end
  local spans = self.spans
  local out, seen = {}, {}
  local function collect(t)
    for k, v in pairs(t) do
      if type(k) == 'number' and k > 0 and type(v) == 'table' and not seen[v] then
        seen[v] = true
        if spans[v] then out[#out + 1] = v else collect(v) end
      end
    end
  end
  collect(node)
  sort(out, function(a, b) return spans[a][1] < spans[b][1] end)
  self.kid_cache[node] = out
  return out
end

-- Inserts text after the last code byte between a and b, or at a when there's
-- none, and returns the source from a to b with it.
function Conv:gap_with(a, b, text)
  local kinds = self.kinds
  local at = nil
  for i = b, a, -1 do
    if kinds[i] ~= 'w' and kinds[i] ~= 'c' then
      at = i
      break
    end
  end
  if not at then return text .. self:gap(a, b) end
  return self:gap(a, at) .. text .. self:gap(at + 1, b)
end

-- The source from a to b followed by a rendered node, whose table brace goes
-- after the code in between when it asks for that. `after_arg` tells that the
-- node follows another argument, which MoonScript lets a table block do
-- without a comma.
function Conv:join(a, b, text, after_arg)
  local mark = sub(text, 1, 1)
  if mark == GLUE then
    return self:gap_with(a, b, ' {') .. sub(text, 2)
  elseif mark == GLUE_ARG then
    local opener = ' {'
    if after_arg then
      local last = self:code_before(b + 1)
      if not last or last < a or sub(self.src, last, last) ~= ',' then opener = ', {' end
    end
    return self:gap_with(a, b, opener) .. sub(text, 2)
  end
  return self:gap(a, b) .. text
end

-- Renders the source of a node from `from` to `to` (its span by default), with
-- the nodes below it rendered. opts.render(kid) can render a kid instead, by
-- returning its text, and opts.ctx(kid) gives the context for rendering one.
function Conv:splice(node, opts)
  opts = opts or {}
  local span = self.spans[node]
  local s, e = opts.from or span[1], opts.to or span[2]
  local out, pos = {}, s
  for _, kid in ipairs(self:kids(node)) do
    local ks, ke = self.spans[kid][1], self.spans[kid][2]
    if ks >= s and ke <= e then
      if ks < pos then
        error(('overlapping nodes at line %d'):format(self:line_of(ks)), 0)
      end
      local text = opts.render and opts.render(kid)
      if text == nil then
        text = self:render(kid, opts.ctx and opts.ctx(kid) or VALUE)
      end
      if ks > pos then
        local joined = self:join(pos, ks - 1, text, opts.list and #out > 0)
        if opts.list and #out > 0 then
          -- one space after a comma, and none before it
          joined = gsub(joined, '^[ \t]*,[ \t]*([^%s])', ', %1')
        end
        out[#out + 1] = joined
      else
        out[#out + 1] = text -- a glue mark passes on to the node around it
      end
      pos = ke + 1
    end
  end
  local rest = self:gap(pos, e)
  if opts.list and #out > 0 then
    rest = gsub(rest, '^[ \t]*,[ \t]*([^%s])', ', %1') -- as before a trailing ...
  end
  out[#out + 1] = rest
  return concat(out)
end

function Conv:render(node, ctx)
  local handler = not self.lists[node] and handlers[node[1]]
  if handler and self.spans[node] then return handler(self, node, ctx or VALUE) end
  return self:splice(node)
end

-- Shifts the lines after the first by delta columns.
local function reindent(text, delta)
  if delta == 0 then return text end
  if delta > 0 then
    local pad = rep(' ', delta)
    return (gsub(text, '\n([^\n])', '\n' .. pad .. '%1'))
  end
  local cut = -delta
  return (gsub(text, '\n( *)', function(ws)
    return '\n' .. sub(ws, math.min(cut, #ws) + 1)
  end))
end

-- whether the rendered text ends with a line of closing brackets
local function ends_with_closer(text)
  return find(text, CLOSE .. '\n[ \t]*[%)%]}]+$') ~= nil
end

-------------------------------------------------------------------------------
-- Blocks and statements
-------------------------------------------------------------------------------

local function is_super_call(stmt)
  return stmt[1] == 'chain' and type(stmt[2]) == 'table' and stmt[2][1] == 'ref'
    and stmt[2][2] == 'super' and #stmt == 3 and stmt[3][1] == 'call'
end

-- Renders a block of statements. opts.tail ({ kind = 'return' } or
-- { kind = 'assign', targets = text, need_else = bool }) is given to the last
-- statement, opts.inline marks a one-line function body, and opts.drop(stmt)
-- removes a statement with its line.
function Conv:render_block(block, opts)
  opts = opts or {}
  local span = self.spans[block]
  if not span then return '' end
  local stmts = self:kids(block)
  local stmt_ctx = STMT
  if opts.inline then
    stmt_ctx = { stmt = true, inline = true }
  elseif opts.fn_body then
    stmt_ctx = { stmt = true, fn_body = true, only_in_fn = #stmts == 1 }
  end
  local out, pos = {}, span[1]
  local drop_next_gap = false
  local blank_lines = 0
  for i, stmt in ipairs(stmts) do
    local ss, se = self.spans[stmt][1], self.spans[stmt][2]
    local gap = self:gap(pos, ss - 1)
    if drop_next_gap then
      -- the block starts at the next statement, after the blank lines that
      -- followed the dropped one, which the caller can keep
      local _, newlines = gsub(gap, '\n', '')
      blank_lines = math.max(newlines - 1, 0)
      gap = ''
      drop_next_gap = false
    end
    if opts.drop and opts.drop(stmt) then
      if i == 1 then
        drop_next_gap = true
      else
        gap = gsub(gap, '%s*$', '')
      end
      out[#out + 1] = gap
    else
      local text
      if i == #stmts and opts.tail then
        text = self:render_tail(stmt, opts.tail, stmt_ctx)
      else
        text = self:render(stmt, stmt_ctx)
      end
      out[#out + 1] = gap
      out[#out + 1] = text
    end
    pos = se + 1
  end
  out[#out + 1] = self:gap(pos, span[2])
  return concat(out), blank_lines
end

local function tail_prefix(tail)
  if tail.kind == 'return' then return 'return ' end
  return tail.targets .. ' = '
end

local ARITHMETIC = {
  ['+'] = true, ['-'] = true, ['*'] = true, ['/'] = true, ['%'] = true,
  ['^'] = true, ['..'] = true,
}

-- Whether an expression has an `or` outside parentheses, as Lua reads its text.
-- MoonScript's tree puts `not` and unary minus around the whole of `a or b` in
-- `not a or b`, which it writes out as it is, for Lua to read as `(not a) or b`.
local function has_open_or(node)
  if type(node) ~= 'table' then return false end
  local kind = node[1]
  if kind == 'exp' then
    for i = 2, #node do
      local part = node[i]
      if part == 'or' or (i % 2 == 0 and has_open_or(part)) then return true end
    end
  elseif kind == 'not' or kind == 'minus' or kind == 'length' then
    return has_open_or(node[2])
  end
  return false
end

-- whether a value can't be false or nil
local function never_falsy(node)
  if type(node) ~= 'table' or has_open_or(node) then return false end
  local kind = node[1]
  if kind == 'string' or kind == 'number' or kind == 'table' or kind == 'fndef'
    or kind == 'comprehension' or kind == 'tblcomprehension' or kind == 'length'
    or kind == 'minus'
  then
    return true
  elseif kind == 'ref' then
    return node[2] == 'true'
  elseif kind == 'parens' then
    return never_falsy(node[2])
  elseif kind == 'exp' then
    for i = 3, #node, 2 do
      if not ARITHMETIC[node[i]] then return false end
    end
    return true
  end
  return false
end

-- the single expression on one line that a branch body consists of, or nil
function Conv:branch_value(body)
  local stmts = self:kids(body)
  local value = stmts[1]
  if #stmts ~= 1 or not VALUE_KINDS[value[1]] or value[1] == 'explist'
    or value[1] == 'with'
  then
    return nil
  end
  local span = self.spans[value]
  if not self:same_line(span[1], span[2]) then return nil end
  return value
end

local MAX_LINE = 100

-- An if value with a then branch whose value can't be false or nil and an else
-- branch, each a single expression, as `c and a or b`, when that fits on its line.
-- Returns nil for any other if.
function Conv:and_or(node)
  local else_branch = node[4]
  if #node ~= 4 or else_branch[1] ~= 'else' then return nil end
  local cond = node[2]
  if type(cond) ~= 'table' or cond[1] == 'assign' then return nil end
  local a = self:branch_value(node[3])
  if not a or not never_falsy(a) then return nil end
  local b = self:branch_value(else_branch[2])
  if not b then return nil end
  -- comments in it would be lost
  local span = self.spans[node]
  for i = span[1], span[2] do
    if self.kinds[i] == 'c' then return nil end
  end

  local cond_text = self:render(cond)
  if node[1] == 'unless' then
    if cond[1] == 'exp' or cond[1] == 'not' then cond_text = '(' .. cond_text .. ')' end
    cond_text = 'not ' .. cond_text
  elseif has_open_or(cond) then
    cond_text = '(' .. cond_text .. ')' -- as and binds tighter than or
  end
  local value_ctx = { after_prefix = true }
  local text = cond_text .. ' and ' .. self:render(a, value_ctx) .. ' or '
    .. self:render(b, value_ctx)

  -- the line it ends up on: the code before the if on its first line, and after it
  -- on its last
  local before = span[1] - self.line_starts[self:line_of(span[1])]
  local line_end = find(self.src, '\n', span[2], true) or #self.src + 1
  if find(text, '\n') or before + #text + (line_end - 1 - span[2]) > MAX_LINE then
    return nil
  end
  return text
end

-- Renders the last statement of a block whose value is returned or assigned.
function Conv:render_tail(stmt, tail, stmt_ctx)
  local kind = stmt[1]
  if kind == 'if' or kind == 'unless' then
    local text = self:and_or(stmt)
    if text then
      -- the last statement of a function or file passes its value on as it is
      if tail.kind == 'return' and tail.top then return text end
      return tail_prefix(tail) .. text
    end
  end
  if kind == 'if' or kind == 'unless' or kind == 'switch' or kind == 'do' then
    -- a nested block ending in a value returns it explicitly
    local inner = tail
    if tail.top then inner = { kind = tail.kind } end
    return self:render(stmt, { stmt = true, tail = inner })
  elseif kind == 'decorated' then
    local dkind = stmt[3][1]
    if (dkind == 'if' or dkind == 'unless') and VALUE_KINDS[stmt[2][1]] then
      return tail_prefix(tail) .. self:render(stmt, { prefixed = true })
    end
    return self:render(stmt, stmt_ctx)
  elseif kind == 'assign' and tail.kind == 'assign' then
    -- MoonScript drops the outer assignment for a branch ending in one
    return self:render(stmt, stmt_ctx)
  elseif VALUE_KINDS[kind] then
    return tail_prefix(tail) .. self:render(stmt, { after_prefix = true })
  elseif (kind == 'for' or kind == 'foreach' or kind == 'while')
    and (tail.kind == 'assign' or tail.explicit)
  then
    self:warn(self.spans[stmt][1], 'a loop as a value')
  end
  return self:render(stmt, stmt_ctx)
end

-- Renders a body after its header, which ends at header_end: a block stays
-- where it is, with the source between, while a body on the header's line moves
-- to lines of its own.
function Conv:render_body(header_end, body, opts)
  local span = self.spans[body]
  if not span then return '' end
  if self:same_line(header_end, span[1]) then
    local indent = self:indent_at(header_end)
    local text = self:render_block(body, opts)
    return '\n' .. indent .. '  ' .. reindent(text, #indent + 2 - #self:indent_at(span[1]))
  end
  return self:gap(header_end + 1, span[1] - 1) .. self:render_block(body, opts)
end

-- the position of the end of the keyword starting at pos
function Conv:keyword_end(pos)
  local _, e = find(self.src, '^[%w_]+', pos)
  return e
end

handlers['if'] = function(self, node, ctx)
  if not ctx.stmt then
    -- an if value inside an expression, which is left to the compiler to reject
    -- when it isn't simple enough for and and or
    local text = self:and_or(node)
    if text then
      if ctx.operand then return '(' .. text .. ')' end
      return text
    end
  end

  local tail = ctx.tail
  local branches = {}

  local function add(n, kw, pos)
    if type(n[2]) == 'table' and n[2][1] == 'assign' then
      self:warn(pos, 'assignment in an if condition')
    end
    branches[#branches + 1] = { kw = kw, pos = pos, cond = n[2], body = n[3] }
    for i = 4, #n do
      local branch = n[i]
      local bpos = self.spans[branch][1]
      if branch[1] == 'elseif' then
        branches[#branches + 1] = { kw = 'elseif', pos = bpos, cond = branch[2], body = branch[3] }
      else
        local stmts = self:kids(branch[2])
        local nested = stmts[1]
        if #stmts == 1 and nested[1] == 'if' and self:same_line(bpos, self.spans[nested][1]) then
          add(nested, 'elseif', bpos) -- else if c
        else
          branches[#branches + 1] = { kw = 'else', pos = bpos, body = branch[2] }
        end
      end
    end
  end
  add(node, node[1], self.spans[node][1])

  local indent = self:indent_at(self.spans[node][1])
  local out = {}
  local has_else = false
  for i, branch in ipairs(branches) do
    if i > 1 then
      local prev_end = self.spans[branches[i - 1].body][2]
      local between = self:gap(prev_end + 1, branch.pos - 1)
      if not find(between, '\n') then between = '\n' .. indent end
      out[#out + 1] = between
    end
    out[#out + 1] = branch.kw
    local header_end
    if branch.cond then
      local cs = self.spans[branch.cond]
      out[#out + 1] = ' ' .. self:render(branch.cond)
      header_end = cs[2]
    else
      has_else = true
      header_end = self:keyword_end(branch.pos)
    end
    out[#out + 1] = self:render_body(header_end, branch.body, { tail = tail })
  end
  if tail and tail.kind == 'assign' and tail.need_else and not has_else then
    out[#out + 1] = '\n' .. indent .. 'else\n' .. indent .. '  ' .. tail.targets .. ' = nil'
  end
  return concat(out)
end

handlers.unless = handlers['if']

handlers.switch = function(self, node, ctx)
  local tail = ctx.tail
  local span = self.spans[node]
  local subject = node[2]
  local out = { self:gap(span[1], self.spans[subject][1] - 1), self:render(subject) }
  local pos = self.spans[subject][2]
  local has_else = false
  local case_indent
  for _, case in ipairs(node[3]) do
    local cs = self.spans[case]
    case_indent = self:indent_at(cs[1])
    out[#out + 1] = self:gap(pos + 1, cs[1] - 1)
    local header_end
    if case[1] == 'case' then
      local vs = self.spans[case[2]]
      out[#out + 1] = self:gap(cs[1], vs[1] - 1) .. self:render(case[2])
      header_end = vs[2]
    else
      has_else = true
      header_end = self:keyword_end(cs[1])
      out[#out + 1] = 'else'
    end
    local body = case[1] == 'case' and case[3] or case[2]
    out[#out + 1] = self:render_body(header_end, body, { tail = tail })
    pos = self.spans[body][2]
  end
  if tail and tail.kind == 'assign' and tail.need_else and not has_else then
    out[#out + 1] = '\n' .. case_indent .. 'else\n' .. case_indent .. '  ' .. tail.targets .. ' = nil'
  end
  out[#out + 1] = self:gap(pos + 1, span[2])
  return concat(out)
end

handlers['do'] = function(self, node, ctx)
  local span = self.spans[node]
  return 'do' .. self:render_body(self:keyword_end(span[1]), node[2], { tail = ctx.tail })
end

handlers['while'] = function(self, node)
  local cond = self.spans[node[2]]
  local header = self:splice(node, { to = cond[2] })
  return header .. self:render_body(cond[2], node[3])
end

handlers.with = function(self, node)
  if node[2][1] == 'assign' then
    self:warn(self.spans[node][1], "assignment in a 'with' header")
  end
  local target = self.spans[node[2]]
  local header = self:splice(node, { to = target[2] })
  return header .. self:render_body(target[2], node[3])
end

handlers['for'] = function(self, node)
  if not node[4] then return self:splice(node) end -- a comprehension clause
  local range = node[3]
  local parts = {}
  for _, exp in ipairs(range) do parts[#parts + 1] = self:render(exp) end
  local header = 'for ' .. node[2] .. ' = ' .. concat(parts, ', ')
  return header .. self:render_body(self.spans[range][2], node[4])
end

handlers.foreach = function(self, node)
  if not node[4] then return self:splice(node) end -- a comprehension clause
  local iter = self.spans[node[3]]
  local header = self:splice(node, { to = iter[2] })
  return header .. self:render_body(iter[2], node[4])
end

handlers.decorated = function(self, node, ctx)
  local stmt, decorator = node[2], node[3]
  local inner_ctx = ctx.prefixed and VALUE or (ctx.stmt and ctx or VALUE)
  return self:splice(node, {
    render = function(kid)
      if kid == stmt then return self:render(stmt, inner_ctx) end
      if kid == decorator then return self:splice(decorator) end
    end,
  })
end

handlers.when = function(self, node)
  local span = self.spans[node]
  local exp = self.spans[node[2]]
  return 'if' .. self:gap(span[1] + 4, exp[1] - 1) .. self:render(node[2]) .. self:gap(exp[2] + 1, span[2])
end

local function check_clauses(self, node)
  local fors = 0
  for _, clause in ipairs(node[3]) do
    if clause[1] == 'for' or clause[1] == 'foreach' then fors = fors + 1 end
  end
  if fors > 1 then
    self:warn(self.spans[node][1], "a comprehension with several 'for' clauses")
  end
  return self:splice(node)
end

handlers.comprehension = check_clauses
handlers.tblcomprehension = check_clauses

handlers.assign = function(self, node, ctx)
  local values = node[3]
  local value = values[1]
  for _, v in ipairs(values) do
    local kind = type(v) == 'table' and v[1]
    if kind == 'for' or kind == 'foreach' or kind == 'while' then
      self:warn(self.spans[node][1], 'a loop as a value')
    end
  end
  if #values == 1 and type(value) == 'table'
    and (value[1] == 'if' or value[1] == 'unless' or value[1] == 'switch')
  then
    if not ctx.stmt then
      self:warn(self.spans[node][1], "an assigned '" .. value[1] .. "' that isn't a statement")
      return self:splice(node)
    end
    local targets = self:render(node[2])
    local simple = value[1] ~= 'switch' and self:and_or(value)
    if simple then return targets .. ' = ' .. simple end
    local new = self.new_names[node] or {}
    local nils = self.nil_names[node] or {}
    local declared, all_new = {}, true
    for _, target in ipairs(node[2]) do
      local name = type(target) == 'table' and target[1] == 'ref' and target[2]
      if name and new[name] then
        declared[#declared + 1] = name
      elseif not (name and nils[name]) then
        all_new = false -- not surely nil before the if
      end
    end
    local indent = self:indent_at(self.spans[node][1])
    local text = ''
    if #declared > 0 then
      text = 'local ' .. concat(declared, ', ') .. '\n' .. indent
    end
    return text .. self:render(value, {
      stmt = true,
      tail = { kind = 'assign', targets = targets, need_else = not all_new },
    })
  end
  local tspan, vspan = self.spans[node[2]], self.spans[values]
  if not tspan or not vspan then return self:splice(node) end
  local values_text = self:render(values)
  if sub(values_text, 1, 1) == GLUE then
    return self:render(node[2]) .. self:join(tspan[2] + 1, vspan[1] - 1, values_text)
  end
  -- one space around the =
  local between = gsub(self:gap(tspan[2] + 1, vspan[1] - 1), '^[ \t]*=[ \t]*$', ' = ')
  return self:render(node[2]) .. between .. values_text
end

handlers['return'] = function(self, node)
  local explist = node[2]
  if type(explist) == 'table' and #explist == 2 and type(explist[2]) == 'table' then
    local value = explist[2]
    local kind = value[1]
    local simple = (kind == 'if' or kind == 'unless') and self:and_or(value)
    if simple then
      return 'return ' .. simple
    elseif kind == 'if' or kind == 'unless' or kind == 'switch' then
      return self:render(value, { stmt = true, tail = { kind = 'return', explicit = true } })
    elseif kind == 'for' or kind == 'foreach' or kind == 'while' then
      self:warn(self.spans[node][1], 'a loop returned as a value')
    end
  end
  return self:splice(node)
end

handlers.import = function(self, node)
  local names, stubs = {}, {}
  for _, name in ipairs(node[2]) do
    if type(name) == 'string' then
      names[#names + 1] = ':' .. name
    else
      stubs[#stubs + 1] = name[2]
    end
  end
  local source = self:render(node[3])
  local lines = {}
  if #names > 0 then lines[1] = '{' .. concat(names, ', ') .. '} = ' .. source end
  local indent = self:indent_at(self.spans[node][1])
  for _, name in ipairs(stubs) do
    lines[#lines + 1] = name .. ' = (...) -> ' .. source .. ':' .. name .. '(...)'
  end
  return concat(lines, '\n' .. indent)
end

handlers.export = function(self, node)
  self:warn(self.spans[node][1], "'export'")
  return self:splice(node)
end

-------------------------------------------------------------------------------
-- Functions
-------------------------------------------------------------------------------

-- whether a statement of a one-line body has values separated by commas
local function has_value_list(stmt)
  local kind = stmt[1]
  if kind == 'explist' then return true end
  if kind == 'assign' then return #stmt[2] > 1 or #stmt[3] > 1 end
  if kind == 'return' then
    return type(stmt[2]) == 'table' and #stmt[2] > 2
  end
  return false
end

local COMPOUND = {
  ['if'] = true, unless = true, switch = true, ['for'] = true, foreach = true,
  ['while'] = true, ['do'] = true,
}

handlers.fndef = function(self, node, ctx)
  local params, body = node[2], node[5]
  local span = self.spans[node]
  local body_span = type(body) == 'table' and self.spans[body]

  -- @x parameters become plain ones, assigned in the body
  local assigns = {}
  local function render_param(param)
    local target = param[1]
    if type(target) == 'table' and (target[1] == 'self' or target[1] == 'self_class') then
      local at = target[1] == 'self' and '@' or '@@'
      assigns[#assigns + 1] = at .. target[2] .. ' = ' .. target[2]
      local text = self:splice(param)
      return (gsub(text, '^@@?', ''))
    end
  end

  -- the arrow ends the header
  local search_from = self.spans[params] and self.spans[params][2] or span[1]
  local _, arrow_end = find(self.src, '[-=]>', search_from)
  local header = self:splice(node, {
    to = arrow_end,
    render = function(kid)
      if kid == params then
        return self:splice(params, { list = true, render = render_param })
      end
    end,
  })

  local member = ctx.member
  local is_new = member == 'new'
  local is_setter = ctx.setter
  local fn_opts = {}
  local stmts = body_span and self:kids(body) or {}
  local last = stmts[#stmts]
  if last and COMPOUND[last[1]] and not is_new and not is_setter then
    fn_opts.tail = { kind = 'return', top = true }
  end
  if is_new and ctx.drop_super then fn_opts.drop = is_super_call end

  local indent = self:indent_at(span[1])
  local inline = body_span and self:same_line(arrow_end, body_span[1])

  -- one-line bodies that become blocks
  local to_block = #assigns > 0
  if inline and #stmts == 1 then
    local stmt = stmts[1]
    if COMPOUND[stmt[1]] then to_block = true end
    -- a for modifier ending a one-line function in a table or the arguments of a
    -- call with parentheses, where it reads both ways
    if ctx.in_list and not ctx.last_bare_arg and stmt[1] == 'decorated'
      and stmt[3][1] == 'comprehension'
    then
      to_block = true
    end
  end

  if not body_span then
    if #assigns > 0 then
      return header .. '\n' .. indent .. '  ' .. concat(assigns, '\n' .. indent .. '  ')
    end
    return header .. self:gap(arrow_end + 1, span[2])
  end

  if inline and not to_block then
    fn_opts.inline = true
    local text = header .. ' ' .. self:render_block(body, fn_opts)
    if ctx.in_list and #stmts == 1 and has_value_list(stmts[1]) then
      return '(' .. text .. ')'
    end
    return text
  end

  if inline then
    local body_indent = indent .. '  '
    local text = self:render_block(body, fn_opts)
    text = reindent(text, #body_indent - #self:indent_at(body_span[1]))
    local lines = {}
    for _, a in ipairs(assigns) do lines[#lines + 1] = a end
    lines[#lines + 1] = text
    return header .. '\n' .. body_indent .. concat(lines, '\n' .. body_indent)
  end

  fn_opts.fn_body = true
  local block_text, blank_lines = self:render_block(body, fn_opts)
  local text = ''
  if find(block_text, '%S') then -- unless all its statements were dropped
    text = self:join(arrow_end + 1, body_span[1] - 1, block_text)
  end
  if #assigns > 0 then
    local body_indent = self:indent_at(body_span[1])
    -- blank lines after a dropped first statement now follow the assignments
    text = '\n' .. body_indent .. concat(assigns, '\n' .. body_indent)
      .. rep('\n', blank_lines) .. text
  end
  return header .. text
end

-------------------------------------------------------------------------------
-- Calls
-------------------------------------------------------------------------------

local function is_block_fn(self, node)
  if type(node) ~= 'table' or node[1] ~= 'fndef' then return false end
  local body = node[5]
  local span = self.spans[node]
  local body_span = type(body) == 'table' and self.spans[body]
  return body_span and not self:same_line(span[1], body_span[1])
end

-- whether a node ends with a function block, after which closing brackets go on
-- a line of their own
local function ends_with_block(self, node)
  if type(node) ~= 'table' or not self.spans[node] then return false end
  if is_block_fn(self, node) then return true end
  -- named arguments on the call's line, not those on the lines below, which
  -- become a table with its own closing brace
  if node[1] == 'table' and self:braceless(node) and not self:starts_line(self.spans[node][1]) then
    local entries = self:kids(node[2])
    local last = entries[#entries]
    return last ~= nil and ends_with_block(self, last[2] or last[1])
  end
  return false
end

-- whether a table node has no braces in the source
function Conv:braceless(node)
  return node[1] == 'table' and sub(self.src, self.spans[node][1], self.spans[node][1]) ~= '{'
end

-- whether an argument can start the arguments of a call without parentheses
local function can_start_bare(self, arg)
  if type(arg) ~= 'table' then return true end
  local kind = arg[1]
  if kind == 'minus' or kind == 'comprehension' or kind == 'parens' then
    return false
  end
  if kind == 'exp' or kind == 'chain' then return can_start_bare(self, arg[2]) end
  return true
end

-- Renders call arguments: a table without braces that isn't the last one gets
-- braces, and functions know they're in a list. `bare` marks the arguments of a
-- call left without parentheses, where the last one runs to the end of the line.
function Conv:render_args(args, bare)
  local list = self:kids(args)
  local last = list[#list]
  return self:splice(args, { list = true,
    ctx = function(kid)
      if kid == last and self:braceless(kid) and not self:starts_line(self.spans[kid][1]) then
        return { in_list = true, arg = true, bare = true }
      end
      if kid == last and bare then
        return { in_list = true, arg = true, last_bare_arg = true }
      end
      return ARG
    end,
  })
end

-- whether a chain ends with a name before its call, so that a table can follow
-- as its only argument, as in f {...} but not in t[1] {...}
local function callee_ends_with_name(chain)
  local before = chain[#chain - 1]
  if type(before) ~= 'table' then return before == 'self' end
  local kind = before[1]
  return kind == 'ref' or kind == 'self' or kind == 'self_class' or kind == 'dot'
    or kind == 'colon'
end

-- Renders a call without parentheses: the call at the end of a chain whose
-- source so far is rendered as `prefix`, with its arguments starting at `pos`.
function Conv:render_bare_call(chain, call, ctx, pos)
  local args = call[2]
  local aspan = self.spans[args]
  local list = self:kids(args)
  local first, last = list[1], list[#list]

  -- a table as the only argument: f {...}
  if #list == 1 and first[1] == 'table' and callee_ends_with_name(chain)
    and (not self:braceless(first) or self:starts_line(aspan[1]))
  then
    return self:join(pos, aspan[1] - 1, self:render(first))
  end

  local keep = false
  if ctx.stmt and not ctx.inline and can_start_bare(self, first) then
    if ends_with_block(self, last) then
      keep = true
    elseif self.opts.spec then
      local callee = chain[2]
      if type(callee) == 'table' and callee[1] == 'ref' then
        if BUSTED[callee[2]] and #chain == 3 then keep = true end
        if callee[2] == 'assert' and #chain >= 4 then keep = true end
      end
    end
  end

  if keep then
    return self:join(pos, aspan[1] - 1, self:render_args(args, true))
  end

  -- f (a) passed (a): the parentheses become the call's, unless they hold a call
  -- or ..., whose values they cut down to one
  local text
  if #list == 1 and first[1] == 'parens' then
    local inner = first[2]
    local inner_call = type(inner) == 'table' and inner[1] == 'chain'
      and inner[#inner][1] == 'call'
    if inner == '...' or inner_call then
      text = self:render(first)
    else
      text = self:render(inner)
    end
  else
    text = self:render_args(args)
  end

  -- code before the arguments, as the ']' ending an index
  local before = self:gap(pos, aspan[1] - 1)
  local lead = gsub(before, '%s+$', '')
  local mark = sub(text, 1, 1)
  if mark == GLUE or mark == GLUE_ARG then
    -- a table block as the only argument
    text = '{' .. sub(before, #lead + 1) .. sub(text, 2)
  end
  if ends_with_closer(text) then
    return lead .. '(' .. text .. ')'
  elseif ends_with_block(self, last) then
    return lead .. '(' .. text .. CLOSE .. '\n' .. self:indent_at(self.spans[chain][1]) .. ')'
  end
  return lead .. '(' .. text .. ')'
end

handlers.chain = function(self, node, ctx)
  local span = self.spans[node]
  local out = {}
  local pos = span[1]
  local n = #node
  for i = 2, n do
    local item = node[i]
    if type(item) == 'table' then
      local ispan = self.spans[item]
      if item[1] == 'call' and not ispan then
        out[#out + 1] = self:render_bare_call(node, item, ctx, pos)
        pos = self.spans[item[2]][2] + 1
      elseif item[1] == 'colon' then
        local prefix = concat(out) .. self:gap(pos, ispan[1] - 1)
        local name = item[2]
        local method
        if prefix == '@' or prefix == '@@' then
          method = prefix .. name
        else
          method = prefix .. ':' .. name
        end
        if i == n then
          return '(...) -> ' .. method .. '(...)' -- a function stub
        end
        out = { method }
        pos = ispan[2] + 1
      elseif item[1] == 'call' then
        out[#out + 1] = self:gap(pos, ispan[1] - 1)
        local c = sub(self.src, ispan[1], ispan[1])
        if c == '!' then
          out[#out + 1] = '()'
        elseif c == '(' then
          local args = item[2]
          if self.spans[args] then
            out[#out + 1] = self:splice(item, {
              render = function(kid)
                if kid == args then return self:render_args(args) end
              end,
            })
          else
            out[#out + 1] = self:splice(item)
          end
        elseif c == '[' then
          out[#out + 1] = '(' .. self:splice(item) .. ')'
        else
          out[#out + 1] = self:splice(item)
        end
        pos = ispan[2] + 1
      elseif ispan then
        out[#out + 1] = self:gap(pos, ispan[1] - 1)
        out[#out + 1] = self:render(item)
        pos = ispan[2] + 1
      end
    end
  end
  out[#out + 1] = self:gap(pos, span[2])
  return concat(out)
end

-------------------------------------------------------------------------------
-- Values
-------------------------------------------------------------------------------

-- Renders a table entry: key: value gets a space after its colon.
function Conv:render_entry(entry, ctx)
  local key, value = entry[1], entry[2]
  if not value or type(key) ~= 'table' or not self.spans[value] then
    return self:splice(entry, { ctx = function() return LIST end })
  end
  local kspan, vspan = self.spans[key], self.spans[value]
  local out = {}
  local es = self.spans[entry][1]
  if kspan then
    out[#out + 1] = self:gap(es, kspan[1] - 1)
    out[#out + 1] = self:render(key)
    es = kspan[2] + 1
  end
  local vctx = { in_list = true, under_key = true, member = ctx and ctx.member,
    setter = ctx and ctx.setter, drop_super = ctx and ctx.drop_super }
  local vtext = self:render(value, vctx)
  local between = self:gap(es, vspan[1] - 1)
  if sub(vtext, 1, 1) == GLUE then
    between = self:gap_with(es, vspan[1] - 1, ' {')
    vtext = sub(vtext, 2)
  elseif find(between, ':$') then
    between = between .. ' ' -- a key touching its value
  elseif value[1] == 'fndef' then
    between = gsub(between, ':  +$', ': ') -- new:  =>
  end
  out[#out + 1] = between
  out[#out + 1] = vtext
  out[#out + 1] = self:gap(vspan[2] + 1, self.spans[entry][2])
  return concat(out)
end

function Conv:render_entries(node)
  local entries = node[2]
  if not self.spans[entries] then return '' end
  return self:splice(entries, { list = true,
    render = function(kid)
      if type(kid[1]) == 'table' or #kid == 2 then return self:render_entry(kid) end
    end,
    ctx = function() return LIST end,
  })
end

handlers.table = function(self, node, ctx)
  local span = self.spans[node]
  if not self:braceless(node) then
    local text = self:splice(node, {
      render = function(kid)
        if kid == node[2] then return self:render_entries(node) end
      end,
    })
    -- a closing brace on a line of its own lines up with the opening line
    return (gsub(text, '\n[ \t]*}$', '\n' .. self:indent_at(span[1]) .. '}'))
  end

  local text = self:render_entries(node)
  local entries = self:kids(node[2])
  local last = entries[#entries]
  local last_value = last and last[2]

  if ctx.stmt and not ctx.only_in_fn then
    -- a table as a statement: one ending a function below other statements gets
    -- its entries on lines of their own
    if ctx.fn_body and self:starts_line(span[1]) then
      local indent = self:indent_at(span[1])
      return '{\n' .. indent .. '  ' .. reindent(text, 2) .. '\n' .. indent .. '}'
    end
    return '{' .. text .. '}'
  end
  if ctx.after_prefix then return '{' .. text .. '}' end

  if self:starts_line(span[1]) then
    -- a table block, or a function's only statement: its '{' goes on the line
    -- before
    -- a table block: its '{' goes on the line before
    local before = self:code_before(span[1])
    local indent = before and self:indent_at(before) or ''
    return (ctx.arg and GLUE_ARG or GLUE) .. text .. CLOSE .. '\n' .. indent .. '}'
  end
  if ctx.bare then return text end

  -- a table nested under a key gets its entries on lines of their own, and so
  -- does a table around one
  local nested = false
  for _, entry in ipairs(entries) do
    local value = entry[2]
    if type(value) == 'table' and value[1] == 'table' and self.spans[value]
      and self:braceless(value) and not self:starts_line(self.spans[value][1])
    then
      nested = true
    end
  end
  if ctx.under_key or nested then
    local indent = self:indent_at(span[1])
    local parts = {}
    for _, entry in ipairs(entries) do
      local etext
      if type(entry[1]) == 'table' or #entry == 2 then
        etext = self:render_entry(entry)
      else
        etext = self:render(entry, LIST)
      end
      etext = reindent(etext, #indent + 2 - #self:indent_at(self.spans[entry][1]))
      parts[#parts + 1] = indent .. '  ' .. etext
    end
    return '{\n' .. concat(parts, '\n') .. '\n' .. indent .. '}'
  end

  if ends_with_block(self, last_value) then
    return '{' .. text .. CLOSE .. '\n' .. self:indent_at(span[1]) .. '}'
  end
  return '{' .. text .. '}'
end

handlers.string = function(self, node)
  local open = node[2]
  if open == "'" or open == '"' then return self:splice(node) end
  local span = self.spans[node]
  if open == '[[' then return self:splice(node) end
  -- a long string with a level
  local content = node[3]
  if not find(content, ']]', 1, true) then
    local source = sub(self.src, span[1], span[2])
    return '[[' .. sub(source, #open + 1, -#open - 1) .. ']]'
  end
  content = gsub(content, '\\', '\\\\')
  content = gsub(content, "'", "\\'")
  return "'" .. content .. "'"
end

-- A line continuing an expression is indented deeper than the line it starts on.
handlers.exp = function(self, node)
  local span = self.spans[node]
  local base = #self:indent_at(span[1])
  local out, pos = {}, span[1]
  local prev_end = nil
  for _, kid in ipairs(self:kids(node)) do
    local ks, ke = self.spans[kid][1], self.spans[kid][2]
    local gap = self:gap(pos, ks - 1)
    if prev_end and not self:same_line(prev_end, ks) then
      local indent = #self:indent_at(ks)
      if indent <= base then
        gap = gsub(gap, '\n[ \t]*$', '\n' .. rep(' ', base + 2))
      end
    end
    out[#out + 1] = gap
    out[#out + 1] = self:render(kid, OPERAND)
    pos = ke + 1
    prev_end = ke
  end
  out[#out + 1] = self:gap(pos, span[2])
  return concat(out)
end

-------------------------------------------------------------------------------
-- Classes
-------------------------------------------------------------------------------

local function is_self_call(stmt, name)
  return type(stmt) == 'table' and stmt[1] == 'chain' and type(stmt[2]) == 'table'
    and stmt[2][1] == 'self' and stmt[2][2] == name and #stmt == 3
    and stmt[3][1] == 'call'
end

-- the key name of an entry, if it's a plain name
local function entry_name(entry)
  local key = entry[1]
  if type(key) == 'table' and key[1] == 'key_literal' then return key[2] end
end

-- @property name: get: ..., set: ... becomes get name: ... and set name: ...
function Conv:render_property(stmt, indent)
  local args = self:kids(stmt[3][2])
  local tbl = args[1]
  local entries = tbl and tbl[1] == 'table' and tbl[2]
  if not entries or #entries ~= 1 then return end
  local name = entry_name(entries[1])
  local accessors = entries[1][2]
  if not name or type(accessors) ~= 'table' or accessors[1] ~= 'table' then return end
  local items = {}
  local getter, setter
  for _, acc in ipairs(accessors[2]) do
    local kind = entry_name(acc)
    if kind == 'get' then getter = acc elseif kind == 'set' then setter = acc else return end
  end
  local prev
  for _, acc in ipairs({ getter or false, setter or false }) do
    if acc then
      local kind = entry_name(acc)
      local value = acc[2]
      local vspan = self.spans[value]
      local text = self:render(value, { setter = kind == 'set', in_list = false })
      text = reindent(text, #indent - #self:indent_at(vspan[1]))
      local sep = ''
      if prev then
        local blank = find(self.src:sub(self.spans[prev][2], self.spans[acc][1]), '\n[ \t]*\n')
        if self.spans[acc][1] < self.spans[prev][1] then blank = nil end
        sep = blank and '\n\n' .. indent or '\n' .. indent
      end
      items[#items + 1] = sep .. kind .. ' ' .. name .. ': ' .. text
      prev = acc
    end
  end
  return concat(items)
end

-- MoonScript adds a class's members before running the statements in its body,
-- where Howlscript runs the body top to bottom. So a member whose value reads a
-- local of the class body assigned above it got nil, and now gets the value.
function Conv:check_member_order(lines)
  local assigned = {}
  -- the names a value reads when it's evaluated, outside the functions in it
  local function reads(node, found)
    if type(node) ~= 'table' then return end
    local kind = not self.lists[node] and node[1]
    if kind == 'fndef' then return end
    if kind == 'ref' and assigned[node[2]] then found[#found + 1] = node[2] end
    for k, v in pairs(node) do
      if type(k) == 'number' and k > 0 and type(v) == 'table' then reads(v, found) end
    end
  end
  for _, line in ipairs(lines) do
    if line[1] == 'stm' then
      local stmt = line[2]
      if type(stmt) == 'table' and stmt[1] == 'assign' then
        for _, target in ipairs(stmt[2]) do
          if type(target) == 'table' and target[1] == 'ref' then assigned[target[2]] = true end
        end
      end
    elseif line[1] == 'props' then
      for i = 2, #line do
        local found = {}
        reads(line[i][2], found)
        if #found > 0 then
          self:warn(self.spans[line][1], "a member reading the class body's '" .. found[1]
            .. "', which MoonScript's members saw as nil")
        end
      end
    end
  end
end

handlers.class = function(self, node)
  local span = self.spans[node]
  local parent, body = node[3], node[4]
  local property_object = type(parent) == 'table' and parent[1] == 'ref'
    and parent[2] == 'PropertyObject'
  local _, name_end = find(self.src, '^class%s+[%w_]+', span[1])
  local parent_span = type(parent) == 'table' and self.spans[parent]
  local header_end = parent_span and parent_span[2] or name_end

  -- a class extending PropertyObject loses its parent
  local header = self:splice(node, { to = property_object and name_end or header_end })
  local body_span = type(body) == 'table' and self.spans[body]
  if not body_span then return header .. self:gap(header_end + 1, span[2]) end

  local lines = self:kids(body)
  local out, pos = { header }, header_end + 1

  self:check_member_order(lines)

  -- metamethod members go in a meta table, where the first stood
  local meta_entries = {}
  for _, line in ipairs(lines) do
    if line[1] == 'props' then
      for i = 2, #line do
        if METAMETHODS[entry_name(line[i]) or ''] then
          meta_entries[#meta_entries + 1] = line[i]
          if entry_name(line[i]) == '__index' then
            self:warn(self.spans[line[i]][1],
              "an __index member, ignored by MoonScript, becomes a fallback")
          end
        end
      end
    end
  end
  local meta_done = false

  for _, line in ipairs(lines) do
    local ls, le = self.spans[line][1], self.spans[line][2]
    local indent = self:indent_at(ls)
    local gap = self:gap(pos, ls - 1)
    local text
    if line[1] == 'props' then
      local metas, others = {}, {}
      for i = 2, #line do
        if METAMETHODS[entry_name(line[i]) or ''] then
          metas[#metas + 1] = line[i]
        else
          others[#others + 1] = line[i]
        end
      end
      if #metas > 0 and #others > 0 then
        self:warn(ls, 'metamethods and other members on one line')
      end
      if #metas > 0 and #others == 0 then
        if meta_done then
          text = DROP
        else
          meta_done = true
          local parts = {}
          for _, entry in ipairs(meta_entries) do
            local etext = self:render_entry(entry)
            etext = reindent(etext, #indent + 2 - #self:indent_at(self.spans[entry][1]))
            parts[#parts + 1] = indent .. '  ' .. etext
          end
          text = 'meta {\n' .. concat(parts, '\n') .. '\n' .. indent .. '}'
        end
      else
        text = self:splice(line, {
          render = function(kid)
            local member = entry_name(kid)
            return self:render_entry(kid, { member = member, drop_super = property_object })
          end,
        })
      end
    else
      local stmt = line[2]
      if is_self_call(stmt, 'property') then
        text = self:render_property(stmt, indent)
        if not text then
          self:warn(ls, 'an @property this converter does not know')
          text = self:render(stmt, STMT)
        end
      elseif is_self_call(stmt, 'meta') then
        local args = self:kids(stmt[3][2])
        if #args == 1 and args[1][1] == 'table' and not self:braceless(args[1]) then
          text = 'meta ' .. self:render(args[1])
        else
          self:warn(ls, 'an @meta call')
          text = self:render(stmt, STMT)
        end
      else
        text = self:splice(line, { ctx = function() return STMT end })
      end
    end
    if text == DROP then
      out[#out + 1] = gsub(gap, '\n[ \t]*$', '')
    else
      out[#out + 1] = gap
      out[#out + 1] = text
    end
    pos = le + 1
  end
  out[#out + 1] = self:gap(pos, span[2])
  return concat(out)
end

-------------------------------------------------------------------------------
-- Files
-------------------------------------------------------------------------------

function Conv:render_file()
  local tree = self.tree
  if not self.spans[tree] then return self.src end
  local stmts = self:kids(tree)
  local last = stmts[#stmts]
  local opts = {}
  -- a module ending in a call returns its value, so that it stands out, unless
  -- the call takes a function block, and one ending in an if returns from it
  if last and last[1] == 'chain' and last[#last][1] == 'call' then
    local call = last[#last]
    local args = not self.spans[call] and self:kids(call[2])
    if not (args and #args > 0 and ends_with_block(self, args[#args])) then
      opts.tail = { kind = 'return' }
    end
  elseif last and COMPOUND[last[1]] then
    opts.tail = { kind = 'return', top = true }
  end
  local text = self:render_block(tree, opts)
  text = self:gap(1, self.spans[tree][1] - 1) .. text .. self:gap(self.spans[tree][2] + 1, #self.src)

  -- a comment ending a line moves above closing brackets placed after it
  text = gsub(text, CLOSE .. '(\n[ \t]*[%)%]}]+)([ \t]+%-%-[^\n]*)', '%2%1')
  text = gsub(text, '[\1\3\4]', '')
  text = gsub(text, '\n\n+$', '\n')

  -- PropertyObject is gone with the parents of its classes
  local _, uses = gsub(text, 'PropertyObject', '')
  if uses == 1 then
    local count
    text = '\n' .. text
    text, count = gsub(text, '\n\n{:PropertyObject} = howl%.util%.moon\n\n', '\n\n')
    if count == 0 then
      text = gsub(text, '\n{:PropertyObject} = howl%.util%.moon\n', '\n')
    end
    text = gsub(text, '^\n+', '')
  end

  local copyright = self.opts.copyright
  if copyright then text = self:update_copyright(text, copyright) end
  return text
end

-- Howl's own files: the years of a copyright end with the year of the
-- conversion, and a file without the usual header gets one, starting from the
-- year it was added.
function Conv:update_copyright(text, copyright)
  local year = tostring(copyright.year)
  text = gsub(text, 'Copyright (%d%d%d%d)[%d%-, ]* The Howl Developers', function(first)
    if first == year then return 'Copyright ' .. year .. ' The Howl Developers' end
    return 'Copyright ' .. first .. '-' .. year .. ' The Howl Developers'
  end)
  if not find(text, '^%-%- Copyright') and not find(text, '\n%-%- Copyright')
    and copyright.first_year
  then
    local first = tostring(copyright.first_year)
    local years = first == year and year or first .. '-' .. year
    text = '-- Copyright ' .. years .. ' The Howl Developers\n'
      .. '-- License: MIT (see LICENSE.md at the top-level directory of the distribution)\n\n'
      .. text
  end
  return text
end

-- Converts MoonScript source to Howlscript. opts.spec renders the busted calls
-- of a spec without parentheses. Returns the Howlscript and a list of warnings,
-- { line, message }, for what needs a look, or nil and an error message when the
-- source can't be parsed.
local function convert(src, opts)
  local ok, conv = pcall(new_converter, src, opts)
  if not ok then return nil, conv end
  local ok2, text = xpcall(function() return conv:render_file() end, function(err)
    if opts and opts.debug then return debug.traceback(err, 2) end
    return err
  end)
  if not ok2 then return nil, text end
  sort(conv.warnings, function(a, b) return a.line < b.line end)
  return text, conv.warnings
end

return {
  convert = convert,
  parse = parse,
}
