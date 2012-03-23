-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Gettext LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'gettext' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '#' * S(': .~') * l.nonnewline^0)

-- Strings.
local string = token(l.STRING, l.delimited_range('"', '\\', true, false, '\n'))

-- Keywords.
local keyword = token(l.KEYWORD, word_match({
  'msgid', 'msgid_plural', 'msgstr', 'fuzzy', 'c-format', 'no-c-format'
}, '-', true))

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Variables.
local variable = token(l.VARIABLE, S('%$@') * l.word)

M._rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'string', string },
  { 'keyword', keyword },
  { 'identifier', identifier },
  { 'variable', variable },
  { 'any_char', l.any_char },
}

return M
