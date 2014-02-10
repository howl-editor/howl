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

  context '(offset handling stress test)', ->
    it 'returns the correct result as compared to ustring', ->
      build = {}
      line = 'äåöLinƏΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣbutnowforsomesingleΤΥΦΧĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏ'
      for i = 1,3000
        build[#build + 1] = line
      s = table.concat build, '\n'
      sci\insert_text 0, s

      for i = 1, 3000 * line.ulen, 3007
        assert.equal s\byte_offset(i), sci\byte_offset(i - 1) + 1

      for i = 1, 3000 * #line, 3007
        assert.equal s\char_offset(i), sci\char_offset(i - 1) + 1

      for i = 2000 * #line, 100, -2003
        sci\delete_range i, 20
        sci\insert_text i, 'ordinary ascii text here'
        s = sci\get_text!
        c_offset = sci\char_offset(i + 100 - 1) + 1
        assert.equal s\char_offset(i + 100), c_offset
        assert.equal s\byte_offset(c_offset), sci\byte_offset(c_offset - 1) + 1

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
