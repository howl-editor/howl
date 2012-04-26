-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- AWK LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'awk' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '#' * l.nonnewline^0)

-- Strings.
local sq_str = l.delimited_range("'", '\\', true, false, '\n')
local dq_str = l.delimited_range('"', '\\', true, false, '\n')
local regex = l.delimited_range('//', '\\', false, false, '\n')
local string = token(l.STRING, sq_str + dq_str) + token(l.REGEX, regex)

-- Numbers.
local number = token(l.NUMBER, l.float + l.integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
  'break', 'continue', 'do', 'delete', 'else', 'exit', 'for', 'function',
  'getline', 'if', 'next', 'nextfile', 'print', 'printf', 'return', 'while'
})

-- Functions.
local func = token(l.FUNCTION, word_match {
  'atan2', 'cos', 'exp', 'gensub', 'getline', 'gsub', 'index', 'int', 'length',
  'log', 'match', 'rand', 'sin', 'split', 'sprintf', 'sqrt', 'srand', 'sub',
  'substr', 'system', 'tolower', 'toupper',
})

-- Constants.
local constant = token(l.CONSTANT, word_match {
  'BEGIN', 'END', 'ARGC', 'ARGIND', 'ARGV', 'CONVFMT', 'ENVIRON', 'ERRNO',
  'FIELDSWIDTH', 'FILENAME', 'FNR', 'FS', 'IGNORECASE', 'NF', 'NR', 'OFMT',
  'OFS', 'ORS', 'RLENGTH', 'RS', 'RSTART', 'RT', 'SUBSEP',
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Variables.
local variable = token(l.VARIABLE, '$' * l.digit^1)

-- Operators.
local operator = token(l.OPERATOR, S('=!<>+-/*%&|^~,:;()[]{}'))

M._rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'function', func },
  { 'constant', constant },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'variable', variable },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

M._foldsymbols = {
  _patterns = { '[{}]', '#' },
  [l.OPERATOR] = { ['{'] = 1, ['}'] = -1 },
  [l.COMMENT] = { ['#'] = l.fold_line_comments('#') }
}

return M
