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

  it 'automatically converts color values to strings', ->
    sci = Scintilla!
    sci\style_set_fore 1, '#112233'
    assert_equal sci\style_get_fore(1), '#112233'

  describe '.dispatch', ->
    context 'for key-press event', ->
      it 'calls the on_keypress handler if present', ->
        sci = Scintilla!
        sci.on_keypress = Spy!
        sci.dispatch sci.sci_ptr, 'key-press', {}
        assert_true sci.on_keypress.called
