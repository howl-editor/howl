import mode from howl
import File from howl.io
import ScintilluaLexer from howl.util

describe 'ScintilluaLexer', ->
  it 'calling it lexes text using the specified Scintillua lexer', ->
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
    lexed = lexer 'awesome stuff'
    assert.same {
      1, 'keyword', 8,
      8, 'whitespace', 9,
      9, 'keyword', 14
    }, lexed

  it 'provides the usual pre-defined Scintillua styles in the lexer', ->
    File.with_tmpfile (file) ->
      file.contents = [[
        local new_tag = lexer.style_tag .. {}
        assert(lexer.style_class ~= nil)
        return {
          _NAME = 'futile_styling_attempt',
          _rules = { { 'any', lexer.any } }
        }
      ]]
      ScintilluaLexer 'style_craze', file

  describe "Scintillua's lexer.load()", ->
    it "can load other Scintillua lexers from registered modes", ->
      File.with_tmpfile (file) ->
        file.contents = [[
          return {
            _NAME = 'embedded',
            _rules = { { 'any', lexer.any } }
          }
        ]]
        lexer = ScintilluaLexer 'embedded', file
        mode.register name: 'embedded', create: -> :lexer

      File.with_tmpfile (file) ->
        file.contents = [[
          local embedded = lexer.load('embedded')
          assert(embedded._RULES ~= nil, 'Failed to load sub lexer')
          return {
            _NAME = 'driver',
            _rules = { { 'any', lexer.any } }
          }
        ]]
        ScintilluaLexer 'driver', file
