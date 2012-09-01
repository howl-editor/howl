import Spy from lunar.spec
import Scintilla from lunar

describe 'Scintilla', ->

  describe 'creation - Scintilla()', ->
    it 'creates the Scintilla widget using _core.sci.new', ->
      sci_new = _core.sci.new
      ptr = sci_new!
      spy = Spy with_return: ptr
      _core.sci.new = spy
      pcall Scintilla
      _core.sci.new = sci_new
      assert_true spy.called

  it '.string_to_color(color) returns a GBR representation of the color', ->
    assert_equal Scintilla.string_to_color('#ffeedd'), 0xddeeff
    assert_equal Scintilla.string_to_color('ffeedd'), 0xddeeff

  describe '.dispatch', ->
    context 'for key-press event', ->
      it 'calls the on_keypress handler if present', ->
        sci = Scintilla!
        sci.on_keypress = Spy!
        sci.dispatch sci.sci_ptr, 'key-press', {}
        assert_true sci.on_keypress.called
