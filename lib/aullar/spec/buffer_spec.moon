-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Buffer = require 'aullar.buffer'

ffi = require 'ffi'

describe 'Buffer', ->

  parts = (b) ->
    p = {}
    if b.gap_start > 1
      p[#p + 1] = ffi.string(b.bytes, b.gap_start - 1)

    post_count = b.size - (b.gap_start - 1)
    if post_count > 0
      p[#p + 1] = ffi.string(b.bytes + b.gap_end - 1, post_count)

    p

  it 'starts out with the gap at the end of the buffer', ->
    b = Buffer 'hello'
    assert.equals 6, b.gap_start
    assert.equals b.gap_size + b.gap_start, b.gap_end

  describe '.text', ->
    it 'is a string representation of the contents', ->
      b = Buffer ''
      assert.equals '', b.text

      b = Buffer 'hello'
      assert.equals 'hello', b.text

    it 'setting it replaces the text completely with the new specified text', ->
      b = Buffer 'hello'
      b.text = 'brave new world'
      assert.equals 'brave new world', tostring b

  describe 'move_gap_to(offset)', ->
    it 'moves the gap to the specified offset', ->
      b = Buffer 'hello'
      b\move_gap_to 3 -- first 'l'
      assert.equals 3, b.gap_start
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { 'he', 'llo' }, parts(b)

      b\move_gap_to 5 -- 'o'
      assert.equals 5, b.gap_start
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { 'hell', 'o' }, parts(b)

  describe 'extend_gap_at(offset, new_size)', ->
    it 'extends the gap to be the specified size at the specified offset', ->
      b = Buffer 'hello'
      new_size = b.gap_size + 10
      b\extend_gap_at 3, new_size -- first 'l'
      assert.equals new_size, b.gap_size
      assert.equals 3, b.gap_start
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { 'he', 'llo' }, parts(b)

      b\extend_gap_at 5, new_size -- 'o'
      assert.equals new_size, b.gap_size
      assert.equals 5, b.gap_start
      assert.equals b.gap_size + b.gap_start, b.gap_end
      assert.same { 'hell', 'o' }, parts(b)

  describe 'lines([start_line, end_line])', ->
    all_lines = (b) -> [ffi.string(l.text, l.size) for l in b\lines 1]

    context 'with no parameters passed', ->
      it 'returns a generator for all available lines in the buffer', ->
        b = Buffer 'line 1\nline 2\nline 3'
        assert.same {
          'line 1',
          'line 2',
          'line 3',
        }, all_lines(b)

    it 'considers an empty last line as a line', ->
      b = Buffer 'line 1\n'
      assert.same {
        'line 1',
        '',
      }, all_lines(b)

    it 'considers an empty buffer as having one line', ->
      b = Buffer ''
      assert.same {
        '',
      }, all_lines(b)

    it 'handles different types of line breaks', ->
      b = Buffer 'line 1\nline 2\r\nline 3\r'
      assert.same {
        'line 1',
        'line 2',
        'line 3',
         '',
      }, all_lines(b)

    it 'is not confused by CR line breaks at the gap boundaries', ->
      b = Buffer 'line 1\r\nline 2'
      b\move_gap_to 8
      assert.same { 'line 1', '', 'line 2' }, all_lines(b)

      b = Buffer 'line 1\n\nline 2'
      b\move_gap_to 8
      assert.same { 'line 1', '', 'line 2' }, all_lines(b)

    it 'is not confused by multiple consecutive line breaks', ->
      b = Buffer 'line 1\n\nline 2'
      b\delete 8, 1
      b\delete 7, 1
      b\insert 7, '\n'
      assert.same {
        'line 1',
        'line 2',
      }, all_lines(b)

    it 'handles various gap positions automatically', ->
      b = Buffer 'line 1\nline 2'
      b\move_gap_to 1
      assert.same { 'line 1', 'line 2' }, all_lines(b)

      b\insert 3, 'x'
      assert.same { 'lixne 1', 'line 2' }, all_lines(b)

      b\insert 9, 'air'
      assert.same { 'lixne 1', 'airline 2' }, all_lines(b)

      b\delete 3, 1
      assert.same { 'line 1', 'airline 2' }, all_lines(b)

      b\delete 8, 3
      assert.same { 'line 1', 'line 2' }, all_lines(b)

      b\move_gap_to b.size + 1
      assert.same { 'line 1', 'line 2' }, all_lines(b)

    it 'provides useful information about the line', ->
      b = Buffer 'line 1\nline 2'
      gen = b\lines!
      line = gen!
      assert.equals 1, line.nr
      assert.equals 6, line.size
      assert.equals 7, line.full_size
      assert.equals 1, line.start_offset
      assert.equals 7, line.end_offset
      assert.is_true line.has_eol

      line = gen!
      assert.equals 2, line.nr
      assert.equals 6, line.size
      assert.equals 6, line.full_size
      assert.equals 8, line.start_offset
      assert.equals 13, line.end_offset
      assert.is_false line.has_eol

    it 'correctly return line sizes given multi-byte line breaks', ->
      b = Buffer 'line 1\r\nline 2'
      gen = b\lines!
      line = gen!
      assert.equals 6, line.size
      assert.equals 8, line.full_size
      assert.is_true line.has_eol

      line = gen!
      assert.equals 6, line.size
      assert.equals 6, line.full_size

  describe 'get_line(nr)', ->
    it 'returns line information for the specified line', ->
      b = Buffer 'line 1\nline 2'
      line = b\get_line 2
      assert.equals 2, line.nr
      assert.equals 6, line.size
      assert.equals 6, line.full_size
      assert.equals 8, line.start_offset
      assert.equals 13, line.end_offset

    it 'return nil for an out-of-bounds line', ->
      b = Buffer 'line 1\nline 2'
      assert.is_nil b\get_line 0
      assert.is_nil b\get_line 3

    it 'returns an empty first line for an empty buffer', ->
      b = Buffer ''
      line = b\get_line 1
      assert.not_nil line
      assert.equals 0, line.size

  describe 'get_line_at_offset(offset)', ->
    it 'returns line information for the line at the specified offset', ->
      b = Buffer 'line 1\nline 2'
      line = b\get_line_at_offset 8
      assert.equals 2, line.nr
      assert.equals 6, line.size
      assert.equals 8, line.start_offset
      assert.equals 13, line.end_offset

    it 'handles boundaries correctly', ->
      b = Buffer '123456\n\n901234'
      assert.is_nil b\get_line_at_offset -1
      assert.is_nil b\get_line_at_offset 0
      assert.equals 1, b\get_line_at_offset(1).nr
      assert.equals 1, b\get_line_at_offset(7).nr
      assert.equals 2, b\get_line_at_offset(8).nr
      assert.equals 3, b\get_line_at_offset(9).nr
      assert.equals 3, b\get_line_at_offset(14).nr
      assert.is_nil b\get_line_at_offset(15)

    it 'returns an empty first line for an empty buffer', ->
      b = Buffer ''
      line = b\get_line_at_offset 1
      assert.not_nil line
      assert.equals 0, line.size

  describe '.nr_lines', ->
    it 'is the number lines in the buffer', ->
      b = Buffer 'line 1\nline 2'
      assert.equals 2, b.nr_lines

      b\insert 3, '\n\n'
      assert.equals 4, b.nr_lines

      b\insert b.size + 1, '\n'
      assert.equals 5, b.nr_lines

      b\delete 3, 1
      assert.equals 4, b.nr_lines

    it 'is 1 for an empty string', ->
      b = Buffer ''
      assert.equals 1, b.nr_lines

  describe 'get_ptr(offset, size)', ->
    it 'returns a pointer to a char buffer starting at offset, valid for <size> bytes', ->
      b = Buffer '123456789'
      assert.equals '3456', ffi.string(b\get_ptr(3, 4), 4)

    it 'returns a valid pointer even if the range overlaps the gap', ->
      b = Buffer '123456789'
      b\insert 4, 'X'
      b\move_gap_to 4
      assert.equals '3X45', ffi.string(b\get_ptr(3, 4), 4)

    it 'returns a valid pointer for an offset greater than the gap start', ->
      b = Buffer '123456789'
      b\move_gap_to 4
      assert.equals '567', ffi.string(b\get_ptr(5, 3), 3)

    it 'returns a valid pointer for an offset and size smaller than the gap start', ->
      b = Buffer '123456789'
      b\insert 6, 'X'
      b\move_gap_to 6
      assert.equals '45', ffi.string(b\get_ptr(4, 2), 2)

    it 'handles boundary conditions', ->
      b = Buffer '123'
      assert.equals '123', ffi.string(b\get_ptr(1, 3), 3)
      assert.equals '1', ffi.string(b\get_ptr(1, 1), 1)
      assert.equals '3', ffi.string(b\get_ptr(3, 1), 1)

    it 'raises errors for illegal values of offset and size', ->
      b = Buffer '123'
      assert.raises 'Illegal', -> b\get_ptr -1, 2
      assert.raises 'Illegal', -> b\get_ptr 1, 4
      assert.raises 'Illegal', -> b\get_ptr 3, 2

  describe 'sub(start_index, end_index)', ->
    it 'returns a string for the given inclusive range', ->
      b = Buffer '123456789'
      assert.equals '234', b\sub(2, 4)
      b\move_gap_to 5
      assert.equals '567', b\sub(5, 7)

  describe 'insert(offset, text, size)', ->
    it 'inserts the given text at the specified position', ->
      b = Buffer 'hello world'
      b\insert 7, 'brave '
      assert.equals 'hello brave world', tostring(b)

    it 'automatically extends the buffer as needed', ->
      b = Buffer 'hello world'
      big_text = string.rep 'x', b.gap_size + 10
      b\insert 7, big_text
      assert.equals "hello #{big_text}world", tostring(b)

    it 'handles insertion at the end of the buffer (i.e. appending)', ->
      b = Buffer ''
      b\insert 1, 'hello'
      b\insert 6, ' world'
      assert.equals 'hello world', tostring(b)

  describe 'delete(offset, count)', ->
    it 'deletes <count> bytes from <offset>', ->
      b = Buffer 'goodbye world'

      b\delete 5, 3 -- random access delete
      assert.same { 'good', ' world' }, parts(b)

      b\delete 4, 1 -- delete back from gap start
      assert.same { 'goo', ' world' }, parts(b)

      b\delete 4, 1 -- delete forward at gap end
      assert.same { 'goo', 'world' }, parts(b)

      assert.equals 'gooworld', tostring(b)

  context 'meta methods', ->
    it 'tostring returns a lua string representation of the buffer', ->
      b = Buffer 'hello world'
      assert.equals 'hello world', tostring b

      b\move_gap_to 1
      assert.equals 'hello world', tostring b

      b\move_gap_to 5
      assert.equals 'hello world', tostring b

  context 'notifications', ->
    it 'sends inserted notifications to all interested listeners', ->
      l1 = on_inserted: spy.new -> nil
      l2 = on_inserted: spy.new -> nil
      b = Buffer 'hello'
      b\add_listener l1
      b\add_listener l2
      b\insert 3, 'xx'
      assert.spy(l1.on_inserted).was_called_with l1, b, offset: 3, text: 'xx', size: 2
      assert.spy(l2.on_inserted).was_called_with l2, b, offset: 3, text: 'xx', size: 2

    it 'sends deleted notifications to listeners', ->
      l1 = on_deleted: spy.new -> nil
      b = Buffer 'hello'
      b\add_listener l1
      b\delete 3, 2
      assert.spy(l1.on_deleted).was_called_with l1, b, offset: 3, text: 'll', size: 2
