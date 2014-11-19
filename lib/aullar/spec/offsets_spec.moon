require 'ljglibs.cdefs.glib'
Offsets = require 'aullar.offsets'
ffi = require 'ffi'
C = ffi.C

describe 'offsets', ->

  char_p = (s) -> ffi.cast('const char *', s)

  local offsets

  before_each ->
    offsets = Offsets!

  describe 'char_offset(byte_offset)', ->
    it 'returns the char_offset for the given byte_offset', ->
      ptr = char_p 'äåö'
      for p in *{
        {0, 0},
        {2, 1},
        {4, 2},
        {6, 3},
      }
        assert.equal p[2], offsets\char_offset ptr, p[1]

  describe 'byte_offset(char_offset)', ->
    it 'returns byte offsets for all character offsets passed as parameters', ->
      ptr = char_p 'äåö'
      for p in *{
        {0, 0},
        {2, 1},
        {4, 2},
        {6, 3},
      }
        assert.equal p[1], offsets\byte_offset ptr, p[2]

  context '(offset handling stress test)', ->
    it 'returns the correct result as compared to glib', ->
      build = {}
      line = 'äåöLinƏΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣbutnowforsomesingleΤΥΦΧĶķĸĹĺĻļĽľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏ'
      for i = 1,3000
        build[#build + 1] = line
      s = table.concat build, '\n'
      ptr = char_p s

      glib_byte_offset = (ptr, char_offset) ->
        next_ptr = C.g_utf8_offset_to_pointer ptr, char_offset
        next_ptr - ptr

      glib_char_offset = (ptr, byte_offset) ->
        next_ptr = ptr + byte_offset
        C.g_utf8_pointer_to_offset ptr, next_ptr

      for i = 1, 3000 * line.ulen, 3007
        assert.equal glib_byte_offset(ptr, i), offsets\byte_offset(ptr, i)

      for i = 1, 3000 * #line, 3007
        assert.equal glib_char_offset(ptr, i), offsets\char_offset(ptr, i)

      new_s = s
      for i = 1, 20
        offset = math.floor math.random! * (#new_s - 2000)
        replacement = 'ordinary ascii text here'
        new_s = s\sub(1, offset) .. replacement .. s\sub(offset + 20)
        ptr = char_p new_s
        offsets\invalidate_from i - 1

        c_offset = offsets\char_offset(ptr, offset + 2000)
        assert.equal glib_char_offset(ptr, offset + 2000), c_offset
        assert.equal glib_byte_offset(ptr, c_offset), offsets\byte_offset(ptr, c_offset)

        if offset > 2000
          c_offset = offsets\char_offset(ptr, offset - 2000)
          assert.equal glib_char_offset(ptr, offset - 2000), c_offset
          assert.equal glib_byte_offset(ptr, c_offset), offsets\byte_offset(ptr, c_offset)
