-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

GapBuffer = require 'aullar.gap_buffer'
ffi = require 'ffi'
C = ffi.C

describe 'GapBuffer', ->
  buffer = (s, gap_size) ->
    GapBuffer 'char', #s, initial: s, :gap_size

  parts = (b) ->
    p = {}
    if b.gap_start > 0
      p[#p + 1] = ffi.string(b.array, b.gap_start)

    post_count = b.size - b.gap_start
    if post_count > 0
      p[#p + 1] = ffi.string(b.array + b.gap_end, post_count)

    p

  get_text = (b) ->
    ffi.string(b\get_ptr(0, b.size), b.size)

  describe 'a new gap buffer', ->
    it 'starts out with the gap at the end of the buffer', ->
      b = buffer '01234'
      assert.equals 5, b.gap_start
      assert.equals b.gap_size + b.gap_start, b.gap_end

    it 'zero-fills the gap', ->
      b = buffer '01234'
      for i = b.gap_start, b.gap_end - 1
        assert.equals 0, b.array[i]

  describe 'set(data, size)', ->
    it 'replaces the buffer contents with the given data', ->
      b = buffer 'first'
      b\set 'second'
      assert.equals 'second', get_text(b)

  describe 'fill(start_offset, end_offset, value)', ->
    it 'fills the specified range with <value>', ->
      b = buffer '0123456789'
      b\fill 2, 6, string.byte('x')
      assert.equals '01xxxxx789', get_text(b)

    it 'handles filling over the buffer gap', ->
      b = buffer '0123456789'
      b\move_gap_to 5
      b\fill 3, 8, string.byte('x')
      assert.equals '012xxxxxx9', get_text(b)
      b\fill 3, 5, string.byte('y')
      assert.equals '012yyyxxx9', get_text(b)

      b\fill 5, 9, string.byte('z')
      assert.equals '012yyzzzzz', get_text(b)

      b\fill 8, 9, string.byte('0')
      assert.equals '012yyzzz00', get_text(b)

    it 'works with non-byte-sized types', ->
      initial = ffi.new 'uint16_t[?]', 3, {1,2,3}
      b = GapBuffer 'uint16_t', 3, :initial
      b\fill 0, 0, 10
      b\fill 1, 2, 23

      ptr = b\get_ptr 0, 3
      assert.equals 10, ptr[0]
      assert.equals 23, ptr[1]
      assert.equals 23, ptr[2]

  describe 'move_gap_to(offset)', ->
    it 'moves the gap to the specified offset', ->
      b = buffer '01234', 10
      b\move_gap_to 2
      assert.equals 2, b.gap_start
      assert.equals 12, b.gap_end
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { '01', '234' }, parts(b)

      b\move_gap_to 4
      assert.equals 4, b.gap_start
      assert.equals 14, b.gap_end
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { '0123', '4' }, parts(b)

    it 'zero-fills the gap', ->
      b = buffer '01234'
      b\move_gap_to 3
      for i = 3, b.gap_end - 1
        assert.equals 0, b.array[i]

  describe 'extend_gap_at(offset, new_size)', ->
    it 'extends the gap to be the specified size at the specified offset', ->
      b = buffer '01234'
      new_size = b.gap_size + 10
      b\extend_gap_at 2, new_size
      assert.equals 2, b.gap_start
      assert.equals new_size, b.gap_size
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { '01', '234' }, parts(b)

      new_size *= 2
      b\extend_gap_at 4, new_size
      assert.equals 4, b.gap_start
      assert.equals new_size, b.gap_size
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { '0123', '4' }, parts(b)

    it 'works with non-byte-sized types', ->
      initial = ffi.new 'uint16_t[?]', 3, {1,2,3}
      b = GapBuffer 'uint16_t', 3, :initial
      new_size = b.gap_size + 10
      b\extend_gap_at 2, new_size
      assert.equals 2, b.gap_start
      assert.equals new_size, b.gap_size
      assert.equals b.gap_size + b.gap_start, b.gap_end

      ptr = b\get_ptr 0, 3
      assert.equals 1, ptr[0]
      assert.equals 2, ptr[1]
      assert.equals 3, ptr[2]

    it 'zero-fills the gap', ->
      b = buffer '01234', 10
      b\extend_gap_at 2, 20
      assert.equals 2, b.gap_start
      assert.equals 22, b.gap_end

      for i = 2, b.gap_end - 1
        assert.equals 0, b.array[i]

    it 'handles extending the gap at the current gap start', ->
      b = buffer '01234'
      b\move_gap_to 2
      new_size = b.gap_size + 10
      b\extend_gap_at 2, new_size
      assert.equals 2, b.gap_start
      assert.equals new_size, b.gap_size
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { '01', '234' }, parts(b)

    it 'handles extending the gap at the end of the buffer', ->
      b = buffer '01234', 4
      b\move_gap_to 2
      new_size = b.gap_size + 10
      b\extend_gap_at 5, new_size
      assert.equals 5, b.gap_start
      assert.equals new_size, b.gap_size
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { '01234' }, parts(b)

  describe 'get_ptr(offset, size)', ->
    it 'returns a pointer to an array starting at offset, valid for <size> bytes', ->
      b = buffer '0123456789'
      assert.equals '3456', ffi.string(b\get_ptr(3, 4), 4)

    it 'returns a valid pointer even if the range overlaps the gap', ->
      b = buffer '0123456789'
      b\insert 4, 'X'
      b\move_gap_to 4
      assert.equals '3X45', ffi.string(b\get_ptr(3, 4), 4)
      assert.equals '3X4', ffi.string(b\get_ptr(3, 3), 3)

    it 'returns a valid pointer for an offset greater than the gap start', ->
      b = buffer '0123456789'
      b\move_gap_to 4
      assert.equals '567', ffi.string(b\get_ptr(5, 3), 3)
      assert.equals '456', ffi.string(b\get_ptr(4, 3), 3)

    it 'returns a valid pointer for an offset and size smaller than the gap start', ->
      b = buffer '0123456789'
      b\move_gap_to 6
      assert.equals '45', ffi.string(b\get_ptr(4, 2), 2)

    it 'handles boundary conditions', ->
      b = buffer '0123'
      assert.equals '123', ffi.string(b\get_ptr(1, 3), 3)
      assert.equals '1', ffi.string(b\get_ptr(1, 1), 1)
      assert.equals '3', ffi.string(b\get_ptr(3, 1), 1)

    it 'raises errors for illegal values of offset and size', ->
      b = buffer '0123'
      assert.raises 'Illegal', -> b\get_ptr -1, 2
      assert.raises 'Illegal', -> b\get_ptr 0, 5
      assert.raises 'Illegal', -> b\get_ptr 3, 2

    it 'works with non-byte-sized types', ->
      initial = ffi.new 'uint16_t[?]', 3, {1,2,3}
      b = GapBuffer 'uint16_t', 3, :initial
      ptr = b\get_ptr 0, 3
      assert.equals 1, ptr[0]
      assert.equals 2, ptr[1]
      assert.equals 3, ptr[2]

      b\move_gap_to 1
      ptr = b\get_ptr 0, 3
      assert.equals 1, ptr[0]
      assert.equals 2, ptr[1]
      assert.equals 3, ptr[2]

    it 'always returns pointers that are zero terminated at the boundaries', ->
      for i = 1,20
        b = buffer '0123456789', 10
        b\move_gap_to 5
        pre_gap_ptr = b\get_ptr(0, 4)
        assert.equals 0, pre_gap_ptr[5]

        cross_gap_ptr = b\get_ptr(4, 2)
        assert.equals 0, cross_gap_ptr[2]

        post_gap_ptr = b\get_ptr(5, 1)
        assert.equals 0, post_gap_ptr[5]

  describe 'insert(offset, data, size)', ->
    context 'when <data> is provided', ->
      it 'inserts the given data at the specified position', ->
        b = buffer 'hello world'
        b\insert 6, 'brave '
        assert.equals 'hello brave world', get_text(b)

    context 'when <data> is not provided', ->
      it 'inserts <size> zero-filled units', ->
        initial = ffi.new 'uint16_t[?]', 3, {1,2,3}
        b = GapBuffer 'uint16_t', 3, :initial
        ptr = b\get_ptr 0, 3
        assert.equals 1, ptr[0]
        assert.equals 2, ptr[1]
        assert.equals 3, ptr[2]

        b\insert 1, nil, 2
        ptr = b\get_ptr 0, 5
        assert.equals 1, ptr[0]
        assert.equals 0, ptr[1]
        assert.equals 0, ptr[2]
        assert.equals 2, ptr[3]
        assert.equals 3, ptr[4]

    it 'automatically extends the buffer as needed', ->
      b = buffer 'hello world'
      big_text = string.rep 'x', b.gap_size + 10
      b\insert 6, big_text
      assert.equals "hello #{big_text}world", get_text(b)

    it 'handles insertion at the end of the buffer (i.e. appending)', ->
      b = buffer ''
      b\insert 0, 'hello'
      b\insert 5, ' world'
      assert.equals 'hello world', get_text(b)

    it 'works with non-byte-sized types', ->
      initial = ffi.new 'uint16_t[?]', 2, {1,4}
      b = GapBuffer 'uint16_t', 3, :initial
      b\insert 1, ffi.new('uint16_t[2]', {2,3}), 2
      ptr = b\get_ptr 0, 4
      assert.equals 1, ptr[0]
      assert.equals 2, ptr[1]
      assert.equals 3, ptr[2]
      assert.equals 4, ptr[3]

  describe 'delete(offset, count)', ->
    it 'deletes <count> units from <offset>', ->
      b = buffer 'goodbye world'

      b\delete 4, 3 -- random access delete
      assert.same { 'good', ' world' }, parts(b)

      b\delete 3, 1 -- delete back from gap start
      assert.same { 'goo', ' world' }, parts(b)

      b\delete 3, 1 -- delete forward at gap end
      assert.same { 'goo', 'world' }, parts(b)

      assert.equals 'gooworld', get_text(b)

    it 'zero-fills the deleted content', ->
      b = buffer 'goodbye world'

      assert_zero_filled = ->
        for i = b.gap_start, b.gap_end - 1
          assert.equals 0, b.array[i]

      b\delete 4, 3 -- random access delete
      assert_zero_filled!

      b\delete 3, 1 -- delete back from gap start
      assert_zero_filled!

      b\delete 3, 1 -- delete forward at gap end
      assert_zero_filled!

  describe 'replace(offset, count, replacement, replacement_size)', ->
    it 'replaces the specified number of unit with the replacement', ->
      b = buffer '12 456 890'
      b\replace 0, 2, 'oh'
      b\replace 3, 3, 'hai'
      b\replace 7, 3, 'cat'
      assert.equals 'oh hai cat', get_text(b)
