import Scintilla from howl
import colors from howl.ui

describe 'Scintilla', ->

  sci = Scintilla!

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
        sci.listener = on_keypress: spy.new -> nil
        sci.dispatch sci.sci_ptr, 'key-press', {}
        assert.spy(sci.listener.on_keypress).was_called(1)

    it 'calls the on_error handler with the error if a handler raise one', ->
      sci.listener = {
        on_keypress: -> error 'BOOM!'
        on_error: spy.new -> nil
      }
      sci.dispatch sci.sci_ptr, 'key-press', {}
      assert.spy(sci.listener.on_error).was_called_with('BOOM!')
