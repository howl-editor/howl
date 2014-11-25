-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

GapBuffer = require 'aullar.gap_buffer'
ffi = require 'ffi'
C = ffi.C

describe 'GapBuffer', ->
  buffer = (s) ->
    GapBuffer 'char', #s, initial: s

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

  it 'starts out with the gap at the end of the buffer', ->
    b = buffer '01234'
    assert.equals 5, b.gap_start
    assert.equals b.gap_size + b.gap_start, b.gap_end

  describe 'set(data, size)', ->
    it 'replaces the buffer contents with the given data', ->
      b = buffer 'first'
      b\set 'second'
      assert.equals 'second', get_text(b)

  describe 'move_gap_to(offset)', ->
    it 'moves the gap to the specified offset', ->
      b = buffer '01234'
      b\move_gap_to 2
      assert.equals 2, b.gap_start
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { '01', '234' }, parts(b)

      b\move_gap_to 4
      assert.equals 4, b.gap_start
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { '0123', '4' }, parts(b)

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

  describe 'insert(offset, data, size)', ->
    it 'inserts the given data at the specified position', ->
      b = buffer 'hello world'
      b\insert 6, 'brave '
      assert.equals 'hello brave world', get_text(b)

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

  describe 'replace(offset, count, replacement, replacement_size)', ->
    it 'replaces the specified number of unit with the replacement', ->
      b = buffer '12 456 890'
      b\replace 0, 2, 'oh'
      b\replace 3, 3, 'hai'
      b\replace 7, 3, 'cat'
      assert.equals 'oh hai cat', get_text(b)
