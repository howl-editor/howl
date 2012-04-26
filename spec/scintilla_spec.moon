import Spy from vilu.spec
import Scintilla from vilu

describe 'Scintilla', ->

  sci_new = _core.sci.new
  sci_ptr = 'ptr'

  before -> _core.sci.new = -> sci_ptr
  after -> _core.sci.new = sci_new

  describe 'creation - Scintilla()', ->
    it 'creates the Scintilla widget using _core.sci.new', ->
      spy = Spy( { with_return: 'ptr' } )
      _core.sci.new = spy
      Scintilla!
      assert_true spy.called

  describe '.dispatch', ->
    context 'for key-press event', ->
      it 'calls the on_keypress handler if present', ->
        sci = Scintilla!
        sci.on_keypress = Spy!
        sci.dispatch sci_ptr, 'key-press', {}
        assert_true sci.on_keypress.called
