-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- JavaScript LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'javascript' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local line_comment = '//' * l.nonnewline_esc^0
local block_comment = '/*' * (l.any - '*/')^0 * P('*/')^-1
local comment = token(l.COMMENT, line_comment + block_comment)

-- Strings.
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local string = token(l.STRING, sq_str + dq_str) + P(function(input, index)
  if index == 1 then return index end
  local i = index
  while input:sub(i - 1, i - 1):match('[ \t\r\n\f]') do i = i - 1 end
  return input:sub(i - 1, i - 1):match('[+%-*%%^!=&|?:;,()%[%]{}]') and
    index or nil
end) * token(l.REGEX, l.delimited_range('/', '\\', nil, nil, '\n') * S('igm')^0)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
  'abstract', 'boolean', 'break', 'byte', 'case', 'catch', 'char', 'class',
  'const', 'continue', 'debugger', 'default', 'delete', 'do', 'double', 'else',
  'enum', 'export', 'extends', 'false', 'final', 'finally', 'float', 'for',
  'function', 'goto', 'if', 'implements', 'import', 'in', 'instanceof', 'int',
  'interface', 'let', 'long', 'native', 'new', 'null', 'package', 'private',
  'protected', 'public', 'return', 'short', 'static', 'super', 'switch',
  'synchronized', 'this', 'throw', 'throws', 'transient', 'true', 'try',
  'typeof', 'var', 'void', 'volatile', 'while', 'with', 'yield'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Operators.
local operator = token(l.OPERATOR, S('+-/*%^!=&|?:;,.()[]{}<>'))

M._rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'identifier', identifier },
  { 'comment', comment },
  { 'number', number },
  { 'string', string },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

M._foldsymbols = {
  _patterns = { '[{}]', '/%*', '%*/', '//' },
  [l.OPERATOR] = { ['{'] = 1, ['}'] = -1 },
  [l.COMMENT] = { ['/*'] = 1, ['*/'] = -1, ['//'] = l.fold_line_comments('//') }
}

return M
