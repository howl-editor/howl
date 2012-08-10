import ActionBuffer, style from vilu.ui
import Scintilla from vilu

describe 'ActionBuffer', ->
  sci = Scintilla!
  buf = ActionBuffer sci

  it 'initialization takes an optional sci parameter', ->
    assert_not_error -> ActionBuffer!
    assert_equal ActionBuffer(sci).sci, sci

  it 'behaves like a Buffer', ->
    buf.text = 'hello'
    assert_equal buf.text, 'hello'
    buf\append ' world'
    assert_equal buf.text, 'hello world'

  describe '.insert(text, pos, style)', ->

    context 'with no specified style', ->

      it 'inserts the text with no specific style', ->
        buf\insert 'hello', 1
        assert_equal style.at_pos(buf, 1), 'unstyled'

    context 'with style specified', ->

      it 'styles the text with the specified style', ->
        buf.text = '||'
        buf\insert 'hello', 2, 'keyword'
        assert_equal style.at_pos(buf, 1), 'unstyled'
        assert_equal style.at_pos(buf, 2), 'keyword'
        assert_equal style.at_pos(buf, 6), 'keyword'
        assert_equal style.at_pos(buf, 7), 'unstyled'

      it 'styles the text with the default style if the style is unknown', ->
        buf\insert 'hello', 1, 'what?'
        assert_equal style.at_pos(buf, 1), 'default'

  describe '.append(text, style)', ->

    context 'with no specified style', ->

      it 'appends the text with no specific style', ->
        buf.text = 'hello'
        buf\append ' world'
        assert_equal style.at_pos(buf, 7), 'unstyled'

    context 'with style specified', ->

      it 'styles the text with the specified style', ->
        buf.text = '|'
        buf\append 'hello', 'keyword'
        assert_equal style.at_pos(buf, 1), 'unstyled'
        assert_equal style.at_pos(buf, 2), 'keyword'
        assert_equal style.at_pos(buf, 6), 'keyword'

      it 'styles the text with the default style if the style is unknown', ->
        buf\append 'again', 'what?'
        assert_equal style.at_pos(buf, buf.size - 1), 'default'
