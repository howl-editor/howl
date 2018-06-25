-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:clean, :is_valid} = require 'howl.util.utf8'
{:get_monotonic_time} = require 'ljglibs.glib'
ffi = require 'ffi'
C = ffi.C

to_hex_string = (s) ->
  parts = {}
  for i = 1, #s
    parts[#parts + 1] = '\\x' .. string.format('%02x', s\byte(i))
  table.concat parts, ' '

describe 'utf8', ->

  describe 'clean(s)', ->
    glib_make_valid = (s) ->
      ptr = C.g_utf8_make_valid(s, #s)
      s = ffi.string ptr
      C.g_free(ptr)
      s

    utf8_clean = (s) ->
      r, size = clean s
      ffi.string r, size

    assert_clean = (s, expected) ->
      rs = utf8_clean s
      unless rs == expected
        assert.equal to_hex_string(expected), to_hex_string(rs)

    it 'returns a clean string as is', ->
      assert_clean '123456789', '123456789'
      assert_clean "åäöƏ⏱🌨", "åäöƏ⏱🌨"

    it 'cleans up incorrect dual sequences', ->
      assert_clean '|\xc3\x24|', '|�$|'
      assert_clean '|\xc3\x24\xc3\x61|', '|�$�a|'
      assert_clean '|\xc3\x24X\xc3\x61|', '|�$X�a|'

    it 'cleans up incorrect three-byte sequences', ->
      -- -- incorrect at second seq byte
      assert_clean '|\xe1\x24|', '|�$|'

      -- incorrect at third seq byte
      assert_clean '|\xe1\x80\x24|', '|��$|'

    it 'cleans up incorrect four-byte sequences', ->
      -- incorrect at second seq byte
      assert_clean '|\xf0\x24|', '|�$|'

      -- incorrect at third seq byte
      assert_clean '|\xf0\x80\x24|', '|��$|'

      -- incorrect at fourth seq byte
      assert_clean '|\xf0\x80\x80\x24|', '|���$|'

    it 'cleans up stray continuation bytes', ->
      assert_clean '|\x80|', '|�|'
      assert_clean '|\x80\x80|', '|��|'
      assert_clean '\x80|', '�|'
      assert_clean '|\x80', '|�'
      assert_clean '\xc2\xa9\xa9', '©�'

    it 'cleans up illegal bytes', ->
      for b = 192, 193
         assert_clean "|#{string.char(b)}|", '|�|'

      for b = 245, 255
         assert_clean "|#{string.char(b)}|", '|�|'

    it 'cleans up broken utf8 at the end', ->
      assert_clean '\x8d\xc7\xe0', '���'

    it 'handles sequence starts within sequences', ->
      assert_clean '\xc7\xe0\x60\x28\x8c', '��`(�'

    it 'handles illegal values in sequences', ->
      assert_clean '\xc4\xf7\x61\xb9', '��a�'

    -- below are some comparison runs with the builtin glib variants useful
    -- for performance testing
    if false
      time = (title, f) ->
        start = get_monotonic_time!
        f!
        done = get_monotonic_time!
        elapsed = (done - start) / 1000000
        print "'#{title}': #{elapsed} elapsed"

      it 'performance', ->
        valid = string.rep 'abcdefghijklmnopqrstuvxyzABCDEFGHIJKLMNOPQRSTUVXYZ', 1000

        for i = 1, 100
          C.g_utf8_validate valid, #valid, nil

        time 'g_utf8_validate', ->
          for i = 1, 1000
            C.g_utf8_validate valid, #valid, nil

        for i = 1, 100
          is_valid valid

        time 'own is_valid', ->
          for i = 1, 1000
            is_valid valid

        for i = 1, 100
          glib_make_valid(valid)

        time 'g_utf8_make_valid CLEAN', ->
          for i = 1, 1000
            ptr = C.g_utf8_make_valid(valid, #valid)
            C.g_free(ptr)

        for i = 1, 100
          clean valid

        time 'own clean CLEAN', ->
          for i = 1, 1000
            clean valid

        broken = string.rep 'ab⏱🌨\xc3\x24hiåäömn\xe1\x80\x24opq\xf0\x24', 1000
        for i = 1, 100
          glib_make_valid(broken)

        time 'g_utf8_make_valid BROKEN', ->
          for i = 1, 1000
            ptr = C.g_utf8_make_valid(broken, #broken)
            C.g_free(ptr)

        for i = 1, 100
          clean broken

        time 'own clean BROKEN', ->
          for i = 1, 1000
            clean broken
