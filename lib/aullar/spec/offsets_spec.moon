require 'ljglibs.cdefs.glib'
Offsets = require 'aullar.offsets'
ffi = require 'ffi'
C = ffi.C
bit = require 'bit'

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

  describe '(char_offset/byte_offset stress test)', ->
    it 'returns the correct result as compared to glib', ->

      glib_byte_offset = (ptr, char_offset) ->
        next_ptr = C.g_utf8_offset_to_pointer ptr, char_offset
        next_ptr - ptr

      glib_char_offset = (ptr, byte_offset) ->
        next_ptr = ptr + byte_offset
        C.g_utf8_pointer_to_offset ptr, next_ptr

      line = 'äåöLinƏΑΒ_ascii_ΓΔΕΖΗΘΙΚΛΜΝΞ(normal)ΟΠΡΣbutnowΤΥΦΧĶķĸĹĺĻļĽBLANKľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏ'
      s = string.rep line, 400
      ptr = char_p s

      -- random access verification test
      for i = 1, 200
        offset = math.floor math.random! * #s
        c_offset = offsets\char_offset ptr, offset
        glib_c_offset = glib_char_offset ptr, offset
        assert.equal glib_c_offset, c_offset

        b_offset = offsets\byte_offset ptr, c_offset
        glib_b_offset = glib_byte_offset ptr, c_offset
        assert.equal glib_b_offset, b_offset

      -- random access modification test
      for i = 1, 1000
        offset = math.max(1, math.floor math.random! * #s - 1)
        -- but let's not get into differences in handling broken UTF-8,
        -- so don't insert new stuff in the middle of a continuation but
        -- let's just insert stuff if we happen upon an ascii range
        if offset == 1 or bit.band(ptr[offset], 0x80) != 0 or bit.band(ptr[offset - 1], 0x80) != 0
          continue

        s = s\sub(1, offset) .. '|insΣrt|' .. s\sub(offset + 1)
        ptr = char_p s
        valid = C.g_utf8_validate(ptr, -1, nil) != 0
        assert(valid, "Incorrect test setup: Invalid UTF-8 produced")
        offsets\invalidate_from offset - 1

        c_offset = offsets\char_offset ptr, offset
        glib_c_offset = glib_char_offset ptr, offset
        assert.equal glib_c_offset, c_offset

        b_offset = offsets\byte_offset ptr, c_offset
        glib_b_offset = glib_byte_offset ptr, c_offset
        assert.equal glib_b_offset, b_offset
