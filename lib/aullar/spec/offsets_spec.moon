require 'ljglibs.cdefs.glib'
Offsets = require 'aullar.offsets'
GapBuffer = require 'aullar.gap_buffer'
ffi = require 'ffi'
C = ffi.C

describe 'offsets', ->

  gap_b = (data) -> GapBuffer 'char', #data, initial: data

  glib_byte_offset = (ptr, char_offset) ->
    next_ptr = C.g_utf8_offset_to_pointer ptr, char_offset
    next_ptr - ptr

  glib_char_offset = (ptr, byte_offset) ->
    next_ptr = ptr + byte_offset
    C.g_utf8_pointer_to_offset ptr, next_ptr

  local offsets

  before_each ->
    offsets = Offsets!

  describe 'char_offset(byte_offset)', ->
    local gb

    before_each ->
      gb = gap_b string.rep('äå45å89', 400)

    verify_page = (page) ->
      b_base = page * 10
      c_base = page * 7

      assert.equal c_base + 0, offsets\char_offset gb, b_base + 0 -- ä
      assert.equal c_base + 1, offsets\char_offset gb, b_base + 2 -- å
      assert.equal c_base + 2, offsets\char_offset gb, b_base + 4 -- 4
      assert.equal c_base + 3, offsets\char_offset gb, b_base + 5 -- 5
      assert.equal c_base + 4, offsets\char_offset gb, b_base + 6 -- å
      assert.equal c_base + 5, offsets\char_offset gb, b_base + 8 -- 8
      assert.equal c_base + 6, offsets\char_offset gb, b_base + 9 -- 9

    it 'returns char offsets for all byte offsets passed as parameters', ->
      for page = 0, 399, 10
        verify_page page

    it 'works over the gap', ->
      for page = 0, 399, 10
        b_base = page * 10
        gb\move_gap_to math.max(0, b_base - 1) -- prev '9' or zero
        verify_page page

  describe 'byte_offset(char_offset)', ->
    local gb

    before_each ->
      gb = gap_b string.rep('äå45å89', 400)

    verify_page = (page) ->
      b_base = page * 10
      c_base = page * 7
      assert.equal b_base + 0, offsets\byte_offset gb, c_base + 0 -- ä
      assert.equal b_base + 2, offsets\byte_offset gb, c_base + 1 -- å
      assert.equal b_base + 4, offsets\byte_offset gb, c_base + 2 -- 4
      assert.equal b_base + 5, offsets\byte_offset gb, c_base + 3 -- 5
      assert.equal b_base + 6, offsets\byte_offset gb, c_base + 4 -- å
      assert.equal b_base + 8, offsets\byte_offset gb, c_base + 5 -- 8
      assert.equal b_base + 9, offsets\byte_offset gb, c_base + 6 -- 9

    it 'returns byte offsets for all character offsets passed as parameters', ->
      for page = 0, 399, 10
        verify_page page

    it 'works over the gap', ->
      for page = 0, 399, 10
        b_base = page * 10
        gb\move_gap_to math.max(0, b_base - 1) -- prev '9' or zero
        verify_page page

  describe '(char_offset/byte_offset stress test)', ->
    local gb, nr_chars, test_data

    before_each ->
      line = 'äåöLinƏΑΒ_ascii_ΓΔΕΖΗΘΙΚΛΜΝΞ(normal)ΟΠΡΣbutnowΤΥΦΧĶķĸĹĺĻļĽBLANKľĿŀŁłŃńŅņŇňŉŊŋŌōŎŏ'
      test_data = string.rep(line, 400)
      gb = gap_b test_data
      nr_chars = tonumber C.g_utf8_strlen(gb.array, gb.size)

    it 'returns the correct result as compared to glib', ->
      for _ = 1, 200
        pos = math.floor math.random! * nr_chars
        b_offset = offsets\byte_offset gb, pos
        glib_b_offset = glib_byte_offset gb.array, pos
        assert.equal glib_b_offset, b_offset

        c_offset = offsets\char_offset gb, b_offset
        glib_c_offset = glib_char_offset gb.array, b_offset
        assert.equal glib_c_offset, c_offset
        assert.equal glib_c_offset, c_offset

    it 'returns the correct result for a changing buffer as compared to glib', ->
      replacement = '<insΣΓt>'
      replacement_len = tonumber C.g_utf8_strlen(ffi.cast('const char *', replacement), #replacement)
      glib_gb = GapBuffer 'char', #test_data, initial: test_data

      for _ = 1, 100
        pos = math.floor math.random! * (nr_chars - 20)
        glib_b_offset = glib_byte_offset glib_gb.array, pos
        b_offset = offsets\byte_offset gb, pos
        assert.equal glib_b_offset, b_offset

        glib_c_offset = glib_char_offset glib_gb.array, b_offset
        c_offset = offsets\char_offset gb, b_offset
        assert.equal pos, glib_c_offset
        assert.equal glib_c_offset, c_offset

        -- insert
        glib_gb\insert b_offset, replacement
        gb\insert b_offset, replacement
        offsets\adjust_for_insert b_offset, #replacement, replacement_len

        -- remove
        del_start_pos = b_offset + #replacement
        del_end_pos = offsets\byte_offset gb, pos + replacement_len + 5
        size = del_end_pos - del_start_pos
        del_text = ffi.string(gb\get_ptr(del_start_pos, size), size)
        assert.is_true(C.g_utf8_validate(ffi.cast('const char *', del_text), size, nil) != 0)

        glib_gb\delete del_start_pos, size
        gb\delete del_start_pos, size
        offsets\adjust_for_delete del_start_pos, size, 5

        glib_gb\compact!
