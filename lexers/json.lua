-- Copyright 2006-2012 Brian "Sir Alaran" Schott. See LICENSE.
-- JSON LPeg lexer.
-- Based off of lexer code by Mitchell.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'json' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '/*' * (l.any - '*/')^0 * P('*/')^-1)

-- Strings.
local sq_str = P('u')^-1 * l.delimited_range("'", '\\', true, false, '\n')
local dq_str = P('U')^-1 * l.delimited_range('"', '\\', true, false, '\n')
local string = token(l.STRING, sq_str + dq_str)

-- Numbers.
local integer = S('+-')^-1 * l.digit^1 * S('Ll')^-1
local number = token(l.NUMBER, l.float + integer)

-- Keywords.
local keyword = token(l.KEYWORD, word_match { "true", "false", "null" })

-- Operators.
local operator = token(l.OPERATOR, S('[]{}:,'))

M._rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'number', number },
  { 'keyword', keyword },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

M._foldsymbols = {
  _patterns = { '[%[%]{}]', '/%*', '%*/' },
  [l.OPERATOR] = { ['['] = 1, [']'] = -1, ['{'] = 1, ['}'] = -1 },
  [l.COMMENT] = { ['/*'] = 1, ['*/'] = -1 }
}

return M
