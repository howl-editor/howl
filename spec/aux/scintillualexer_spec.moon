import File from lunar.fs
import ScintilluaLexer from lunar.aux

describe 'ScintilluaLexer', ->
  it ':lex lexes text using the specified Scintillua lexer', ->
    tmpfile = File.tmpfile!
    tmpfile.contents = [[
      local l = lexer
      local token, word_match = l.token, l.word_match
      local ws = token(l.WHITESPACE, l.space^1)
      local keyword = token(l.KEYWORD, word_match {
        'awesome',
        'stuff',
      })
      local M = { _NAME = 'spec' }
      M._rules = {
        { 'whitespace', ws },
        { 'keyword', keyword },
      }
      return M
    ]]
    lexer = ScintilluaLexer 'spec', tmpfile
    tmpfile\delete!
    lexed = lexer\lex 'awesome stuff'
    assert.same lexed, {
      {'keyword', 8},
      {'spec_whitespace', 9},
      {'keyword', 14}
    }
