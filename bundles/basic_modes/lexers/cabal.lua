-- LPeg lexer for Cabal files (Haskell)

local l = lexer
local token, word_match = l.token, l.word_match
local P, S = lpeg.P, lpeg.S

local M = {_NAME = 'cabal'}

-- Whitespace
local ws = token(l.WHITESPACE, l.space^1)

-- Comments
local comment = token(l.COMMENT, '--' * l.nonnewline_esc^0)

-- Strings
local string = token(l.STRING, l.delimited_range('"', '\\'))

-- Chars
local char = token(l.STRING, l.delimited_range("'", "\\", false, false, '\n'))

-- Numbers
local number = token(l.NUMBER, l.float + l.integer)

-- Sections
local section = token(l.KEYWORD, word_match({
  'executable', 'library', 'benchmark', 'test-suite', 'source-repository', 'flag', 'common'
},'-',true))

-- Identifiers
local word = (l.alnum + S("-._'#"))^0
local identifier = token(l.IDENTIFIER, (l.alpha + '_') * word)

-- Operators
local op = l.punct - S('()[]{}')
local operator = token(l.OPERATOR, op)

-- Colon-delimited labels (e.g. main-is:)
local label = token(l.TYPE, word * P(":") * l.space^1)

M._rules = {
  {'whitespace', ws},
  {'keyword', section},
  {'type', label},
  {'identifier', identifier},
  {'string', string},
  {'char', char},
  {'comment', comment},
  {'number', number},
  {'operator', operator},
  {'any_char', l.any_char},
}

return M
