-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Turns Howlscript source into an array of tokens, ending with an 'eof' token.
--
-- Every token is a table with:
--   t       the type: 'name', 'keyword', 'number', 'string', 'op' or 'eof'
--   v       the name, keyword, operator or number text
--   line    the line the token starts on
--   col     the byte column the token starts at
--   first   true if the token is the first on its line
--   indent  the indentation of the line the token is on (a tab counts as 4)
--   sb, sa  true if whitespace (or the start or end of the source) comes directly
--           before or after the token
--
-- String tokens also carry `q`, the opening quote (`'`, `"` or `[` for long
-- strings), and `parts`. A long string has a single part with its literal text. A
-- quoted string has text parts, ready to emit inside the original quotes, and for
-- each `#{...}` an interpolation part `{ tokens = {...} }`.
--
-- Lua-only keywords (end, function, goto, repeat, until) are lexed as names, since
-- Howlscript allows them as keys and field names; the compiler rejects them as
-- variable names.

-- The JIT only slows code this recursive and branchy down: it keeps recording
-- traces that abort, which made compiling several times slower.
jit.off(true, true)

local raise = require('howlscript.errors').raise

-- string functions are used directly rather than as methods, since Howl gives
-- strings an __index function that makes method calls slow
local byte, sub, find, match, gsub, gmatch = string.byte, string.sub, string.find, string.match, string.gsub, string.gmatch

local keywords = {}
for kw in ([[
  and break class continue do else elseif export false for if in local
  nil not or return switch then true unless when while with
]]):gmatch('%a+') do
  keywords[kw] = true
end

local ops3 = { ['...'] = true, ['..='] = true }
local ops2 = {
  ['..'] = true, ['=='] = true, ['=>'] = true, ['!='] = true, ['~='] = true,
  ['<='] = true, ['>='] = true, ['+='] = true, ['++'] = true, ['-='] = true,
  ['->'] = true, ['*='] = true, ['/='] = true, ['%='] = true, ['@@'] = true,
}
local ops1 = {
  ['.'] = true, ['='] = true, ['<'] = true, ['>'] = true, ['+'] = true,
  ['-'] = true, ['*'] = true, ['/'] = true, ['%'] = true, ['^'] = true,
  ['#'] = true, ['('] = true, [')'] = true, ['['] = true, [']'] = true,
  ['{'] = true, ['}'] = true, [','] = true, [':'] = true, ['@'] = true,
}

local B_NL, B_CR, B_SPACE, B_TAB = byte('\n'), byte('\r'), byte(' '), byte('\t')
local B_FF, B_BACKSLASH = byte('\f'), byte('\\')

local function is_space(b)
  return b == B_SPACE or b == B_TAB or b == B_CR or b == B_FF
end

local Lexer = {}
Lexer.__index = Lexer

local function new_lexer(src, pos, line, line_start, indent, tokens)
  return setmetatable({
    src = src,
    pos = pos,
    line = line,
    line_start = line_start, -- byte position where the current line starts
    indent = indent,         -- indentation of the current line
    at_line_start = true,    -- no token seen yet on the current line
    sb = true,               -- whitespace seen since the previous token
    tokens = tokens or {},
  }, Lexer)
end

function Lexer:error(message, pos, line, line_start)
  pos = pos or self.pos
  raise(message, line or self.line, pos - (line_start or self.line_start) + 1)
end

function Lexer:newline()
  self.line = self.line + 1
  self.line_start = self.pos
  self.at_line_start = true
  self.sb = true
end

-- Adds a token spanning [spos, self.pos), starting on `line` (with `line_start`).
function Lexer:add(t, v, spos, line, line_start)
  local first = self.at_line_start
  if first then
    -- indentation is measured on the line the token starts
    local ws = match(self.src, '^[ \t]*', line_start)
    local _, tabs = gsub(ws, '\t', '')
    self.indent = #ws - tabs + tabs * 4
  end

  local tok = {
    t = t,
    v = v,
    line = line,
    col = spos - line_start + 1,
    first = first,
    indent = self.indent,
    sb = self.sb,
    pos = spos,
  }
  self.tokens[#self.tokens + 1] = tok
  self.at_line_start = false
  self.sb = false
  return tok
end

local finish

-- Scans a quoted string starting at the quote. Returns its parts.
function Lexer:quoted_string(q)
  local src = self.src
  local sline, sline_start, spos = self.line, self.line_start, self.pos
  -- line breaks inside the string mustn't count as a new line for the token itself
  local at_line_start, sb = self.at_line_start, self.sb
  local qb = byte(q)
  local parts = {}
  local buf = {}
  local pos = self.pos + 1

  local function flush()
    if #buf > 0 then
      parts[#parts + 1] = table.concat(buf)
      buf = {}
    end
  end

  while true do
    local b = byte(src, pos)
    if not b then
      self:error('unterminated string', spos, sline, sline_start)
    elseif b == qb then
      pos = pos + 1
      break
    elseif b == B_BACKSLASH then
      local nb = byte(src, pos + 1)
      if not nb then
        self:error('unterminated string', spos, sline, sline_start)
      end
      buf[#buf + 1] = sub(src, pos, pos + 1)
      pos = pos + 2
      if nb == B_NL then
        self.pos = pos
        self:newline()
      elseif nb == B_CR and byte(src, pos) == B_NL then
        buf[#buf + 1] = '\n'
        pos = pos + 1
        self.pos = pos
        self:newline()
      end
    elseif b == B_NL or b == B_CR then
      -- a raw line break; Lua needs it escaped, which keeps the lines aligned too
      if b == B_CR and byte(src, pos + 1) == B_NL then
        pos = pos + 1
      end
      buf[#buf + 1] = '\\\n'
      pos = pos + 1
      self.pos = pos
      self:newline()
    elseif q == '"' and b == byte('#') and byte(src, pos + 1) == byte('{') then
      flush()
      local inner = new_lexer(src, pos + 2, self.line, self.line_start, self.indent)
      inner.at_line_start = false
      inner.sb = false
      local line, col = self.line, pos - self.line_start + 1
      inner.opened_at = { pos, self.line, self.line_start }
      inner:run(true)
      if #inner.tokens == 0 then
        self:error('empty string interpolation', pos)
      end
      finish(inner.tokens, inner.line, inner.pos - inner.line_start + 1, inner.indent)
      parts[#parts + 1] = { tokens = inner.tokens, line = line, col = col }
      pos = inner.pos + 1 -- past the closing '}'
      self.line, self.line_start = inner.line, inner.line_start
    else
      local stop = find(src, '[\\\r\n#' .. q .. ']', pos + 1) or #src + 1
      buf[#buf + 1] = sub(src, pos, stop - 1)
      pos = stop
    end
  end

  flush()
  self.pos = pos
  self.at_line_start, self.sb = at_line_start, sb
  return parts, sline, sline_start, spos
end

function Lexer:long_string()
  local src = self.src
  local spos, sline, sline_start = self.pos, self.line, self.line_start
  local _, stop = find(src, ']]', spos, true)
  if not stop then
    self:error('unterminated long string', spos)
  end
  local text = sub(src, spos, stop)
  -- count the lines spanned, keeping line_start right for what follows
  for nl in gmatch(text, '()\n') do
    self.line = self.line + 1
    self.line_start = spos + nl
  end
  self.pos = stop + 1
  local tok = self:add('string', nil, spos, sline, sline_start)
  tok.q = '['
  tok.parts = { text }
  return tok
end

function Lexer:number()
  local src, pos = self.src, self.pos
  local stop
  if match(src, '^0[xX]', pos) then
    stop = select(2, find(src, '^0[xX]%x*', pos))
    if byte(src, stop + 1) == byte('.') then
      stop = select(2, find(src, '^%.%x*', stop + 1))
    end
    local e = select(2, find(src, '^[pP][+-]?%d+', stop + 1))
    stop = e or stop
  else
    stop = select(2, find(src, '^%d*', pos))
    -- a '.' only belongs to the number if it's not the start of '..'
    if byte(src, stop + 1) == byte('.') and byte(src, stop + 2) ~= byte('.') then
      stop = select(2, find(src, '^%.%d*', stop + 1))
    end
    local e = select(2, find(src, '^[eE][+-]?%d+', stop + 1))
    stop = e or stop
  end
  local suffix = select(2, find(src, '^[uU]?[lL][lL]', stop + 1))
    or select(2, find(src, '^[iI]', stop + 1))
  stop = suffix or stop

  if match(src, '^[%w_]', stop + 1) then
    self:error('malformed number', pos)
  end

  self.pos = stop + 1
  return self:add('number', sub(src, pos, stop), pos, self.line, self.line_start)
end

-- Lexes until the end of the source, or with `in_interpolation` until the '}'
-- closing a string interpolation, leaving pos at that brace.
function Lexer:run(in_interpolation)
  local src = self.src
  local depth = 0

  while true do
    local pos = self.pos
    local b = byte(src, pos)

    if not b then
      if in_interpolation then
        local at = self.opened_at
        self:error('unterminated string interpolation', at[1], at[2], at[3])
      end
      break
    end

    if b == B_NL then
      self.pos = pos + 1
      self:newline()
    elseif is_space(b) then
      self.pos = pos + 1
      self.sb = true
    elseif b == byte('-') and byte(src, pos + 1) == byte('-') then
      local prev = self.tokens[#self.tokens]
      if prev and not self.sb and (prev.t == 'name' or (prev.t == 'op' and prev.v == ']')) then
        -- '--' touching a name or ']' is the decrement operator
        self.pos = pos + 2
        self:add('op', '--', pos, self.line, self.line_start)
      else
        self.pos = find(src, '\n', pos, true) or #src + 1
        self.sb = true
      end
    elseif match(src, '^[%a_]', pos) then
      local stop = select(2, find(src, '^[%a_][%w_]*', pos))
      local word = sub(src, pos, stop)
      self.pos = stop + 1
      if sub(word, 1, 4) == '__hs' then
        self:error("names starting with '__hs' are reserved for the compiler", pos)
      end
      if (word == 'or' or word == 'and') and byte(src, stop + 1) == byte('=')
        and byte(src, stop + 2) ~= byte('=') then
        self.pos = stop + 2
        self:add('op', word .. '=', pos, self.line, self.line_start)
      else
        self:add(keywords[word] and 'keyword' or 'name', word, pos, self.line, self.line_start)
      end
    elseif match(src, '^%d', pos) or match(src, '^%.%d', pos) then
      self:number()
    elseif b == byte("'") or b == byte('"') then
      local q = sub(src, pos, pos)
      local parts, sline, sline_start, spos = self:quoted_string(q)
      local tok = self:add('string', nil, spos, sline, sline_start)
      tok.q = q
      tok.parts = parts
    elseif b == byte('[') and byte(src, pos + 1) == byte('[') then
      self:long_string()
    elseif b == byte('[') and match(src, '^%[=+%[', pos) then
      self:error("long strings have no levels in Howlscript; use [[...]], or a quoted string for text containing ']]'", pos)
    else
      local three, two, one = sub(src, pos, pos + 2), sub(src, pos, pos + 1), sub(src, pos, pos)
      local op = ops3[three] and three or ops2[two] and two or ops1[one] and one
      if op then
        if in_interpolation then
          if op == '{' then
            depth = depth + 1
          elseif op == '}' then
            if depth == 0 then return end
            depth = depth - 1
          end
        end
        self.pos = pos + #op
        self:add('op', op, pos, self.line, self.line_start)
      elseif one == '\\' then
        self:error("'\\' is not used for method calls in Howlscript; use ':', as in obj:method()", pos)
      elseif one == '!' then
        self:error("'!' is not an operator in Howlscript; call with '()' and negate with 'not'", pos)
      elseif one == ';' then
        self:error("unexpected ';'; statements end at the end of the line", pos)
      else
        self:error(string.format("unexpected character '%s'", match(src, '^[%z\1-\127\194-\244][\128-\191]*', pos)), pos)
      end
    end
  end
end

-- Sets `sa` for each token, and ends the list with an 'eof' token at line:col.
finish = function(tokens, line, col, indent)
  for i = 1, #tokens do
    local nxt = tokens[i + 1]
    tokens[i].sa = not nxt or nxt.sb
  end

  tokens[#tokens + 1] = {
    t = 'eof',
    line = line,
    col = col,
    first = true,
    indent = indent,
    sb = true,
    sa = true,
  }
end

local function lex(src)
  local lexer = new_lexer(src, 1, 1, 1, 0)
  lexer:run(false)
  finish(lexer.tokens, lexer.line, lexer.pos - lexer.line_start + 1, 0)
  return lexer.tokens
end

return {
  lex = lex,
  keywords = keywords,
}
