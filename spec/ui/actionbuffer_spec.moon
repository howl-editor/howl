import ActionBuffer, style from howl.ui
import Scintilla from howl

describe 'ActionBuffer', ->
  sci = Scintilla!
  buf = ActionBuffer sci

  it 'initialization takes an optional sci parameter', ->
    assert.not_error -> ActionBuffer!
    assert.equal ActionBuffer(sci).sci, sci

  it 'behaves like a Buffer', ->
    buf.text = 'hello'
    assert.equal buf.text, 'hello'
    buf\append ' world'
    assert.equal buf.text, 'hello world'

  describe '.insert(text, pos, style)', ->

    context 'with no specified style', ->

      it 'inserts the text with no specific style', ->
        buf\insert 'hello', 1
        assert.equal style.at_pos(buf, 1), 'unstyled'

    context 'with style specified', ->

      it 'styles the text with the specified style', ->
        buf.text = '˫˫'
        buf\insert 'hƏllo', 2, 'keyword'
        assert.equal style.at_pos(buf, 1), 'unstyled'
        assert.equal style.at_pos(buf, 2), 'keyword'
        assert.equal style.at_pos(buf, 6), 'keyword'
        assert.equal style.at_pos(buf, 7), 'unstyled'

      it 'styles the text with the default style if the style is unknown', ->
        buf\insert 'hello', 1, 'what?'
        assert.equal style.at_pos(buf, 1), 'default'

  describe '.append(text, style)', ->

    context 'with no specified style', ->

      it 'appends the text with no specific style', ->
        buf.text = 'hello'
        buf\append ' world'
        assert.equal style.at_pos(buf, 7), 'unstyled'

    context 'with style specified', ->

      it 'styles the text with the specified style', ->
        buf.text = '˫'
        buf\append 'hƏllo', 'keyword'
        assert.equal style.at_pos(buf, 1), 'unstyled'
        assert.equal style.at_pos(buf, 2), 'keyword'
        assert.equal style.at_pos(buf, 6), 'keyword'

      it 'styles the text with the default style if the style is unknown', ->
        buf\append 'again', 'what?'
        assert.equal 'default', (style.at_pos(buf, buf.length - 1))

  describe 'style(start_pos, end_pos, style)', ->
    it 'applies <style> for the inclusive text range given', ->
      buf.text = 'hƏllo'
      buf\style 2, 4, 'keyword'
      assert.equal style.at_pos(buf, 1), 'unstyled'
      assert.equal style.at_pos(buf, 2), 'keyword'
      assert.equal style.at_pos(buf, 4), 'keyword'
      assert.equal style.at_pos(buf, 5), 'unstyled'
