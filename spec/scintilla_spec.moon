import Scintilla from howl
import colors from howl.ui

describe 'Scintilla', ->

  sci = Scintilla!

  describe 'creation - Scintilla()', ->
    it 'creates the Scintilla widget using _core.sci.new', ->
      sci_new = _core.sci.new
      ptr = sci_new!
      spy = Spy with_return: ptr
      _core.sci.new = spy
      pcall Scintilla
      _core.sci.new = sci_new
      assert.is_true spy.called

  it 'raw() returns a temporary string for the entire document', ->
    sci\add_text 3, 'foo'
    assert.equal 'foo', sci\raw!
    assert.equal 3, #sci\raw!

  describe 'color handling', ->
    it 'automatically converts between color values and strings', ->
      sci\style_set_fore 1, '#112233'
      assert.equal sci\style_get_fore(1), '#112233'

    it 'colors can be specified by name', ->
      sci\style_set_fore 1, 'green'
      assert.equal sci\style_get_fore(1), 'green'

  describe '.dispatch', ->
    context 'for key-press event', ->
      it 'calls the on_keypress handler if present', ->
        sci.listener = on_keypress: Spy!
        sci.dispatch sci.sci_ptr, 'key-press', {}
        assert.is_true sci.listener.on_keypress.called
