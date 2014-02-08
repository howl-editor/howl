import Scintilla, offsets from howl

describe 'offsets', ->
  local sci, o

  before_each ->
    sci = Scintilla!
    o = offsets!

  describe 'char_offset(ptr, byte_offset)', ->
    it 'returns the char_offset for the given <byte_offset>', ->
      sci\insert_text 0, 'äåö'
      for p in *{
        {0, 0},
        {2, 1},
        {4, 2},
        {6, 3},
      }
        assert.equal p[2], o\char_offset sci\get_character_pointer!, p[1]

  describe 'byte_offset(ptr, char_offset)', ->
    it 'returns the byte offset for the given <char_offset>', ->
      sci\insert_text 0, 'äåö'
      for p in *{
        {0, 0},
        {2, 1},
        {4, 2},
        {6, 3},
      }
        assert.equal p[1], o\byte_offset sci\get_character_pointer!, p[2]
