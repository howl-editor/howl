import style from howl.ui
import styler, Scintilla, Buffer from howl

describe 'styler', ->
  sci = Scintilla!
  buffer = Buffer {}, sci
  style.define 's1', color: '#334455'
  style.define 's2', color: '#334455'

  lex_res = (t) -> -> t

  describe 'style_text(sci, buffer, end_pos, lexer)', ->

    it 'styles the buffers text according to the triplet series returned by the lexer', ->
      buffer.text = 'foo'
      styler.style_text sci, buffer, #buffer, lex_res { 1, 's1', 2, 2, 's2', 4 }
      assert.equal 's1', (style.at_pos(buffer, 1))
      assert.equal 's2', (style.at_pos(buffer, 2))
      assert.equal 's2', (style.at_pos(buffer, 3))

    it 'styles any holes with the default style', ->
      buffer.text = 'foo'
      styler.style_text sci, buffer, #buffer, lex_res { 2, 's2', 3 }
      assert.equal 'default', (style.at_pos(buffer, 1))
      assert.equal 's2', (style.at_pos(buffer, 2))
      assert.equal 'default', (style.at_pos(buffer, 3))

    it 'undefined styles are replaced with "default"', ->
      buffer.text = 'foo'
      styler.style_text sci, buffer, #buffer, lex_res { 1, 'wat', 4 }
      assert.equal 'default', (style.at_pos(buffer, 1))
