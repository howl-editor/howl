import Scintilla from howl
import colors from howl.ui

describe 'Scintilla', ->

  local sci

  before_each ->
    sci = Scintilla!

  describe 'character_count()', ->
    it 'returns the number of characters in the document', ->
      sci\insert_text 0, '123'
      assert.equal 3, sci\character_count!
      sci\insert_text 0, 'HƏllo'
      assert.equal 8, sci\character_count!

  describe 'is_multibyte()', ->
    it 'returns true when the document contains multibyte characters', ->
      assert.is_false sci\is_multibyte()
      sci\insert_text 0, 'HƏllo'
      assert.is_true sci\is_multibyte()
      sci\delete_range 1, 4
      assert.is_false sci\is_multibyte()

  describe 'char_offset(byte_offset)', ->
    it 'returns the char_offset for the given byte_offset', ->
      sci\insert_text 0, 'äåö'
      for p in *{
        {0, 0},
        {2, 1},
        {4, 2},
        {6, 3},
      }
        assert.equal p[2], sci\char_offset p[1]

  describe 'byte_offset(char_offset)', ->
    it 'returns byte offsets for all character offsets passed as parameters', ->
      sci\insert_text 0, 'äåö'
      for p in *{
        {0, 0},
        {2, 1},
        {4, 2},
        {6, 3},
      }
        assert.equal p[1], sci\byte_offset p[2]

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
