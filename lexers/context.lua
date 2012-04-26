-- Copyright 2006-2012 Robert Gieseke. See LICENSE.
-- ConTeXt LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'context' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, '%' * l.nonnewline^0)

-- Commands.
local command = token(l.KEYWORD, '\\' * (l.alpha^1 + S('#$&~_^%{}')))

-- Sections.
local section = token('section', '\\' * word_match {
  'part', 'chapter', 'section', 'subsection', 'subsubsection', 'title',
  'subject', 'subsubject', 'subsubsubject'
})

-- ConTeXt environments.
local environment = token('environment', '\\' * (P('start') + 'stop') * l.word)

-- Operators.
local operator = token(l.OPERATOR, S('$&#{}[]'))

M._rules = {
  { 'whitespace', ws },
  { 'comment', comment },
  { 'environment', environment },
  { 'section', section},
  { 'keyword', command },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

M._tokenstyles = {
  { 'environment', l.style_tag },
  { 'section', l.style_class },
}

M._foldsymbols = {
  _patterns = { '\\start', '\\stop', '[{}]', '%%' },
  ['environment'] = { ['\\start'] = 1, ['\\stop'] = -1 },
  [l.OPERATOR] = { ['{'] = 1, ['}'] = -1 },
  [l.COMMENT] = { ['%'] = l.fold_line_comments('%') }
}

-- Embedded Lua.
local luatex = l.load('lua')
local luatex_start_rule = #P('\\startluacode') * environment
local luatex_end_rule = #P('\\stopluacode') * environment
l.embed_lexer(M, luatex, luatex_start_rule, luatex_end_rule)


return M
