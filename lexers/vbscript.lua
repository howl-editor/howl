-- Copyright 2006-2012 Mitchell mitchell.att.foicica.com. See LICENSE.
-- VisualBasic LPeg lexer.

local l = lexer
local token, style, color, word_match = l.token, l.style, l.color, l.word_match
local P, R, S = lpeg.P, lpeg.R, lpeg.S

local M = { _NAME = 'vbscript' }

-- Whitespace.
local ws = token(l.WHITESPACE, l.space^1)

-- Comments.
local comment = token(l.COMMENT, (P("'") + 'Rem ') * l.nonnewline^0)

-- Strings.
local string = token(l.STRING, l.delimited_range('"', nil, true, false, '\n'))

-- Numbers.
local number = token(l.NUMBER, (l.float + l.integer) * S('LlUuFf')^-2)

-- Keywords.
local keyword = token(l.KEYWORD, word_match {
  -- Control.
  'If', 'Then', 'Else', 'ElseIf', 'While', 'Wend', 'For', 'To', 'Each',
  'In', 'Step', 'Case', 'Select', 'Return', 'Continue', 'Do',
  'Until', 'Loop', 'Next', 'With', 'Exit',
  -- Operators.
  'Mod', 'And', 'Not', 'Or', 'Xor', 'Is',
  -- Storage types.
  'Call', 'Class', 'Const', 'Dim', 'ReDim', 'Preserve', 'Function', 'Sub',
  'Property', 'End', 'Set', 'Let', 'Get', 'New', 'Randomize', 'Option',
  'Explicit', 'On', 'Error', 'Execute',
  -- Storage modifiers.
  'Private', 'Public', 'Default',
  -- Constants.
  'Empty', 'False', 'Nothing', 'Null', 'True'
})

-- Types.
local type = token(l.TYPE, word_match {
  'Boolean', 'Byte', 'Char', 'Date', 'Decimal', 'Double', 'Long', 'Object',
  'Short', 'Single', 'String'
})

-- Identifiers.
local identifier = token(l.IDENTIFIER, l.word)

-- Operators.
local operator = token(l.OPERATOR, S('=><+-*^&:.,_()'))

M._rules = {
  { 'whitespace', ws },
  { 'keyword', keyword },
  { 'type', type },
  { 'comment', comment },
  { 'identifier', identifier },
  { 'string', string },
  { 'number', number },
  { 'operator', operator },
  { 'any_char', l.any_char },
}

return M
