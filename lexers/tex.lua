-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- Plain TeX LPeg lexer.
-- Modified by Robert Gieseke.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'tex' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '%' * l.nonnewline^0)

-- TeX environments.
local environment = token('environment', '\\' * (P('begin') + 'end') * l.word)

-- Commands.
local command = token(l.KEYWORD, '\\' * (l.alpha^1 + S('#$&~_^%{}')))

-- Operators.
local operator = token(l.OPERATOR, S('$&#{}[]'))

M._rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'environment', environment },
  { 'keyword', command },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

M._tokenstyles = {
  { 'environment', l.style_tag },
}

M._foldsymbols = {
  _patterns = { '\\begin', '\\end', '[{}]', '%%' },
  [l.COMMENT] = { ['%'] = l.fold_line_comments('%') },
  ['environment'] = { ['\\begin'] = 1, ['\\end'] = -1 },
  [l.OPERATOR] = { ['{'] = 1, ['}'] = -1 }
}

return M
