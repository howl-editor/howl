-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Ini LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'ini' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, #S(';#') * l.starts_line(S(';#') *
                                 l.nonnewline^0))

-- Strings.
local sq_str = l.delimited_range("'", '\\', true)
local dq_str = l.delimited_range('"', '\\', true)
local label = l.delimited_range('[]', nil, true, false, '\n')
local string = token(l.STRING, sq_str + dq_str + label)

-- Numbers.
local dec = l.digit^1 * ('_' * l.digit^1)^0
local oct_num = '0' * S('01234567_')^1
local integer = S('+-')^-1 * (l.hex_num + oct_num + dec)
local number = token(l.NUMBER, (l.float + integer))

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
  'true', 'false', 'on', 'off', 'yes', 'no'
})

-- Identifiers.
local word = (l.alpha + '_') * (l.alnum + S('_.'))^0
local identifier = token(l.IDENTIFIER, word)

-- Operators.
local operator = token(l.OPERATOR, '=')

M._rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'identifier', identifier },
  { 'string', string },
  { 'comment', comment },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

M._LEXBYLINE = true

return M
