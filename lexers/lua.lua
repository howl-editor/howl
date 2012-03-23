-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Lua LPeg lexer.
-- Original written by Peter Odding, 2007/04/04.

local l = lexer
local token, word_match = l.token, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'lua' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

local longstring = #('[[' + ('[' * P('=')^0 * '[')) * P(function(input, index)
  local level = input:match('^%[(=*)%[', index)
  if level then
    local _, stop = input:find(']'..level..']', index, true)
    return stop and stop + 1 or #input + 1
  end
end)

-- Comments.
local line_comment = '--' * l.nonnewline^0
local block_comment = '--' * longstring
local comment = token(l.COMMENT, block_comment + line_comment)

-- Strings.
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local string = token(l.STRING, sq_str + dq_str) +
               token('longstring', longstring)

-- Numbers.
local lua_integer = P('-')^-1 * (l.hex_num + l.dec_num)
local number = token(l.NUMBER, l.float + lua_integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
  'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function',
  'goto', 'if', 'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then',
  'true', 'until', 'while'
})

-- Functions.
local func = token(l.FUNCTION, word_match {
  'assert', 'collectgarbage', 'dofile', 'error', 'getmetatable', 'ipairs',
  'load', 'loadfile', 'next', 'pairs', 'pcall', 'print', 'rawequal', 'rawget',
  'rawlen', 'rawset', 'require', 'select', 'setmetatable', 'tonumber',
  'tostring', 'type', 'xpcall'
})

-- Constants.
local constant = token(l.CONSTANT, word_match {
  '_G', '_VERSION'
})

-- Libraries.
local library = token('library', word_match({
  -- Coroutine.
  'coroutine', 'coroutine.create', 'coroutine.resume', 'coroutine.running',
  'coroutine.status', 'coroutine.wrap', 'coroutine.yield',
  -- Module.
  'package', 'package.config', 'package.cpath', 'package.loaded',
  'package.loadlib', 'package.path', 'package.preload', 'package.searchers',
  'package.searchpath',
  -- String.
  'string', 'string.byte', 'string.char', 'string.dump', 'string.find',
  'string.format', 'string.gmatch', 'string.gsub', 'string.len', 'string.lower',
  'string.match', 'string.rep', 'string.reverse', 'string.sub', 'string.upper',
  -- Table.
  'table', 'table.concat', 'table.insert', 'table.pack', 'table.remove',
  'table.sort', 'table.unpack',
  -- Math.
  'math', 'math.abs', 'math.acos', 'math.asin', 'math.atan2', 'math.atan',
  'math.ceil', 'math.cos', 'math.cosh', 'math.deg', 'math.exp', 'math.floor',
  'math.fmod', 'math.frexp', 'math.huge', 'math.ldexp', 'math.log', 'math.max',
  'math.min', 'math.modf', 'math.pi', 'math.pow', 'math.rad', 'math.random',
  'math.randomseed', 'math.sin', 'math.sinh', 'math.sqrt', 'math.tan',
  'math.tanh',
  -- Bit32.
  'bit32', 'bit32.arshift', 'bit32.band', 'bit32.bnot', 'bit32.bor',
  'bit32.btest', 'bit32.extract', 'bit32.lrotate', 'bit32.lshift',
  'bit32.replace', 'bit32.rrotate', 'bit32.rshift', 'bit32.xor',
  -- IO.
  'io', 'io.close', 'io.flush', 'io.input', 'io.lines', 'io.open', 'io.output',
  'io.popen', 'io.read', 'io.stderr', 'io.stdin', 'io.stdout', 'io.tmpfile',
  'io.type', 'io.write',
  -- OS.
  'os', 'os.clock', 'os.date', 'os.difftime', 'os.execute', 'os.exit',
  'os.getenv', 'os.remove', 'os.rename', 'os.setlocale', 'os.time',
  'os.tmpname',
  -- Debug.
  'debug', 'debug.debug', 'debug.gethook', 'debug.getinfo', 'debug.getlocal',
  'debug.getmetatable', 'debug.getregistry', 'debug.getupvalue',
  'debug.getuservalue', 'debug.sethook', 'debug.setlocal', 'debug.setmetatable',
  'debug.setupvalue', 'debug.setuservalue', 'debug.traceback',
  'debug.upvalueid', 'debug.upvaluejoin'
}, '.'))

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Labels.
local label = token(l.LABEL, '::' * l.word * '::')

-- Operators.
local operator = token(l.OPERATOR, '~=' + S('+-*/%^#=<>;:,.{}[]()'))

M._rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'constant', constant },
  { 'library', library },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'label', label },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

M._tokenstyles = {
  { 'longstring', l.style_string },
  { 'library', l.style_type }
}

local function fold_longcomment(text, pos, line, s, match)
  if match == '[' then
    if line:find('^%[=*%[', s) then return 1 end
  elseif match == ']' then
    if line:find('^%]=*%]', s) then return -1 end
  end
  return 0
end

M._foldsymbols = {
  _patterns = { '%l+', '[%({%)}]', '[%[%]]', '%-%-' },
  [l.KEYWORD] = {
    ['if'] = 1, ['do'] = 1, ['function'] = 1, ['end'] = -1, ['repeat'] = 1,
    ['until'] = -1
  },
  [l.COMMENT] = {
    ['['] = fold_longcomment, [']'] = fold_longcomment,
    ['--'] = l.fold_line_comments('--')
  },
  longstring = { ['['] = 1, [']'] = -1 },
  [l.OPERATOR] = { ['('] = 1, ['{'] = 1, [')'] = -1, ['}'] = -1 }
}

return M
