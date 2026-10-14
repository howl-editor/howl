-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- Compile errors. The lexer, parser and compiler raise them as tables carrying the
-- position, and they're formatted as `chunk:line:col: message`, followed by the
-- offending source line and a caret pointing at the column.

local CompileError = {}
CompileError.__index = CompileError
CompileError.__tostring = function(e)
  return string.format('%d:%d: %s', e.line, e.col, e.message)
end

-- `col` is a byte column, and `len`, if known, the length in bytes of what the
-- error is about.
local function raise(message, line, col, len)
  error(setmetatable({ message = message, line = line, col = col, len = len }, CompileError), 0)
end

local function is_compile_error(v)
  return getmetatable(v) == CompileError
end

local function source_line(source, nr)
  local line = 1
  for text in (source .. '\n'):gmatch('([^\n]*)\n') do
    if line == nr then return (text:gsub('\r$', '')) end
    line = line + 1
  end
  return ''
end

-- The display name for a chunk name, as Lua does it: '@path' and '=name' are shown
-- without their prefix.
local function display_name(chunkname)
  if not chunkname then return '<howlscript>' end
  return (chunkname:gsub('^[@=]', ''))
end

local function format(err, source, chunkname)
  local text = source_line(source, err.line)
  local prefix = text:sub(1, err.col - 1)
  -- the column is reported in characters, so multibyte text doesn't skew it
  local _, chars = prefix:gsub('[^\128-\191]', '')
  -- the caret line keeps the tabs of the source line, so the caret lines up
  local caret = prefix:gsub('[^\128-\191]', function(c)
    return c == '\t' and '\t' or ' '
  end):gsub('[\128-\191]', '')

  return string.format('%s:%d:%d: %s\n  %s\n  %s^',
    display_name(chunkname), err.line, chars + 1, err.message, text, caret)
end

return {
  raise = raise,
  is_compile_error = is_compile_error,
  format = format,
  display_name = display_name,
}
