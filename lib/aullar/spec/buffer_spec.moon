-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Buffer = require 'aullar.buffer'
require 'ljglibs.cdefs.glib'

ffi = require 'ffi'
bit = require 'bit'
C = ffi.C

describe 'Buffer', ->

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

    it 'sets the text as one undo', ->
      b = Buffer 'hello'
      b.text = 'brave new world'
      b\undo!
      assert.equals 'hello', b.text

  describe 'lines([start_line, end_line])', ->
    all_lines = (b) -> [ffi.string(l.ptr, l.size) for l in b\lines 1]

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
      b.text_buffer\move_gap_to 7
      assert.same { 'line 1', '', 'line 2' }, all_lines(b)

      b = Buffer 'line 1\n\nline 2'
      b.text_buffer\move_gap_to 7
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
      b.text_buffer\move_gap_to 0
      assert.same { 'line 1', 'line 2' }, all_lines(b)

      b\insert 3, 'x'
      assert.same { 'lixne 1', 'line 2' }, all_lines(b)

      b\insert 9, 'air'
      assert.same { 'lixne 1', 'airline 2' }, all_lines(b)

      b\delete 3, 1
      assert.same { 'line 1', 'airline 2' }, all_lines(b)

      b\delete 8, 3
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
      assert.equals 'line 1', line.text
      assert.is_true line.has_eol

      line = gen!
      assert.equals 2, line.nr
      assert.equals 6, line.size
      assert.equals 6, line.full_size
      assert.equals 8, line.start_offset
      assert.equals 13, line.end_offset
      assert.equals 'line 2', line.text
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

  describe 'pair_match_forward(offset, closing [, end_offset])', ->
    it 'returns the offset of the closing pair character', ->
      b = Buffer '1[34]6'
      assert.equals 5, b\pair_match_forward 2, ']'

    it 'handles nested pairs', ->
      b = Buffer '1[3[56]8]0'
      assert.equals 9, b\pair_match_forward 2, ']'

    it 'accounts for the gap', ->
      b = Buffer '1[3[56]8]0'
      gap_buffer = b.text_buffer
      for gap_pos = 1, 10
        gap_buffer\move_gap_to gap_pos - 1
        assert.equals 9, b\pair_match_forward 2, ']'

    it 'returns nil if no match was found', ->
      b = Buffer '1[3'
      assert.is_nil b\pair_match_forward 2, ']'

    it 'stops the search at <end_offset>', ->
      b = Buffer '1[34]6'
      assert.equals 5, b\pair_match_forward 2, ']', 6
      assert.equals 5, b\pair_match_forward 2, ']', 5
      assert.is_nil b\pair_match_forward 2, ']', 4

  describe 'pair_match_backward(offset, opening [, end_offset])', ->
    it 'returns the offset of the closing preceeding pair character', ->
      b = Buffer '1[34]6'
      assert.equals 2, b\pair_match_backward 5, '['

    it 'handles nested pairs', ->
      b = Buffer '1[3[56]8]0'
      assert.equals 2, b\pair_match_backward 9, '['

    it 'accounts for the gap', ->
      b = Buffer '1[3[56]8]0'
      gap_buffer = b.text_buffer
      for gap_pos = 1, 10
        gap_buffer\move_gap_to gap_pos - 1
        assert.equals 2, b\pair_match_backward 9, '['

    it 'returns nil if no match was found', ->
      b = Buffer '12]4'
      assert.is_nil b\pair_match_backward 3, '['

    it 'stops the search at <end_offset>', ->
      b = Buffer '1[34]6'
      assert.equals 2, b\pair_match_backward 5, '[', 1
      assert.equals 2, b\pair_match_backward 5, '[', 2
      assert.is_nil b\pair_match_backward 5, '[', 3

  describe 'markers', ->
    local buffer, markers

    before_each ->
      buffer = Buffer '123456789'
      markers = buffer.markers

    it 'updates markers with inserts', ->
      markers\add name: 'test', start_offset: 2, end_offset: 4
      buffer\insert 1, '!'
      assert.same {}, markers\at 2
      assert.same { name: 'test', start_offset: 3, end_offset: 5 }, markers\at(3)[1]

      buffer\insert 4, '!'
      assert.same { name: 'test', start_offset: 3, end_offset: 6 }, markers\at(3)[1]

    it 'updates markers with deletes', ->
      markers\add name: 'test', start_offset: 2, end_offset: 5
      buffer\delete 1, 1
      assert.same {}, markers\at 5
      assert.same { name: 'test', start_offset: 1, end_offset: 4 }, markers\at(1)[1]

      buffer\delete 2, 1
      assert.same { name: 'test', start_offset: 1, end_offset: 3 }, markers\at(1)[1]

      buffer\delete 1, 2
      assert.same {}, markers\at 1

  describe 'get_line(nr)', ->
    it 'returns line information for the specified line', ->
      b = Buffer 'line 1\nline 2'
      line = b\get_line 2
      assert.equals 2, line.nr
      assert.equals 6, line.size
      assert.equals 6, line.full_size
      assert.equals 8, line.start_offset
      assert.equals 13, line.end_offset
      assert.equals 'line 2', line.text

    it 'return nil for an out-of-bounds line', ->
      b = Buffer 'line 1\nline 2'
      assert.is_nil b\get_line 0
      assert.is_nil b\get_line 3

    it 'returns an empty first line for an empty buffer', ->
      b = Buffer ''
      line = b\get_line 1
      assert.not_nil line
      assert.equals 0, line.size

    it 'works fine with a last empty line', ->
      b = Buffer '123\n'
      line = b\get_line 2
      assert.is_not_nil line
      assert.equals 2, line.nr
      assert.equals '', line.text
      assert.equals 5, line.start_offset
      assert.equals 5, line.end_offset

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
      assert.equals 3, b\get_line_at_offset(15).nr
      assert.is_nil b\get_line_at_offset(16)

    it 'returns an empty first line for an empty buffer', ->
      b = Buffer ''
      line = b\get_line_at_offset 1
      assert.not_nil line
      assert.equals 0, line.size

    it 'works fine with a last empty line', ->
      b = Buffer '123\n'
      assert.is_not_nil b\get_line_at_offset(5)
      assert.equals 2, b\get_line_at_offset(5).nr

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

  describe 'sub(start_index [, end_index])', ->
    it 'returns a string for the given inclusive range', ->
      b = Buffer '123456789'
      assert.equals '234', b\sub(2, 4)
      b\delete 4, 1
      assert.equals '678', b\sub(5, 7)
      b\insert 4, 'X'
      assert.equals '123X56789', b\sub(1, 9)

    it 'omitting end_index retrieves the contents until the end', ->
      b = Buffer '12345'
      assert.equals '2345', b\sub(2)
      assert.equals '5', b\sub(5)

    it 'specifying an end_index greater than size retrieves the contents until the end', ->
      b = Buffer '12345'
      assert.equals '2345', b\sub(2, 6)
      assert.equals '45', b\sub(4, 10)

    it 'specifying an start_index greater than size return an empty string', ->
      b = Buffer '12345'
      assert.equals '', b\sub(6, 6)
      assert.equals '', b\sub(6, 10)
      assert.equals '', b\sub(10, 12)

    it 'works fine with a last empty line', ->
      b = Buffer '123\n'
      assert.equals 2, b.nr_lines
      assert.equals '123\n', b\sub b\get_line(1).start_offset, b\get_line(2).end_offset

  describe 'insert(offset, text, size)', ->
    it 'inserts the given text at the specified position', ->
      b = Buffer 'hello world'
      b\insert 7, 'brave '
      assert.equals 'hello brave world', tostring(b)

    it 'automatically extends the buffer as needed', ->
      b = Buffer 'hello world'
      big_text = string.rep 'x', 5000
      b\insert 7, big_text
      assert.equals "hello #{big_text}world", tostring(b)

    it 'handles insertion at the end of the buffer (i.e. appending)', ->
      b = Buffer ''
      b\insert 1, 'hello\n'
      assert.equals 'hello\n', tostring(b)
      assert.equals 'hello', b\get_line(1).text
      b\insert b.size + 1, 'world'
      assert.equals 'hello\nworld', tostring(b)
      assert.equals 'world', b\get_line(2).text

    it 'invalidates any previous line information', ->
      b = Buffer '\n456\n789'
      line_text_ptr = b\get_line(3).ptr
      b\insert 1, '123'
      assert.not_equals line_text_ptr, b\get_line(3).ptr

    it 'updates the styling to keep the existing styling', ->
      b = Buffer '123\n567'
      b.styling\set 1, 7, 'keyword'
      b\insert 5, 'XX'
      assert.same { 1, 'keyword', 5, 7, 'keyword', 10 }, b.styling\get(1, 9)

  describe 'delete(offset, count)', ->
    it 'deletes <count> bytes from <offset>', ->
      b = Buffer 'goodbye world'

      b\delete 5, 3 -- random access delete
      assert.equals 'good world', tostring(b)

    it 'handles boundary conditions', ->
      b = Buffer '123'
      b\delete 1, 3
      assert.equals '', tostring(b)

      b.text = '123'
      b\delete 3, 1
      assert.equals '12', tostring(b)

    it 'invalidates any previous line information', ->
      b = Buffer '123\n456\n789'
      line_text_ptr = b\get_line(3).ptr
      b\delete 1, 1
      assert.not_equals line_text_ptr, b\get_line(3).ptr

    it 'updates the styling to keep the existing styling', ->
      b = Buffer '123\n567'
      b.styling\set 1, 3, 'keyword'
      b.styling\set 5, 7, 'string'
      b\delete 3, 3
      assert.same { 1, 'keyword', 3, 3, 'string', 5 }, b.styling\get(1, 4)

  describe 'replace(offset, count, replacement, replacement_size)', ->
    it 'replaces the specified number of characters with the replacement', ->
      b = Buffer '12 456 890'
      b\replace 1, 2, 'oh'
      b\replace 4, 3, 'hai'
      b\replace 8, 3, 'cat'
      assert.equals 'oh hai cat', b.text

  describe 'char_offset(byte_offset)', ->
    it 'returns the char_offset for the given byte_offset', ->
      b = Buffer 'äåö'
      for p in *{
        {1, 1},
        {3, 2},
        {5, 3},
        {7, 4},
      }
        assert.equal p[2], b\char_offset p[1]

  describe 'byte_offset(char_offset)', ->
    it 'returns byte offsets for all character offsets passed as parameters', ->
      b = Buffer 'äåö'
      for p in *{
        {1, 1},
        {3, 2},
        {5, 3},
        {7, 4},
      }
        assert.equal p[1], b\byte_offset p[2]

  describe '.length', ->
    it 'is the number of code points in the buffer', ->
      b = Buffer ''
      assert.equal 0, b.length

      b.text = '123'
      assert.equal 3, b.length

      b.text = 'äåö'
      assert.equal 3, b.length

    it 'updates automatically with modification', ->
      b = Buffer string.rep('äåö', 100)
      assert.equal 300, b.length
      for i = 1, 40
        cur_length = b.length

        pos = math.floor math.random(b.size - 10)
        insert_pos = b\byte_offset(b\char_offset(pos))
        b\insert insert_pos, 'äåö'
        assert.equal cur_length + 3, b.length
        b\delete insert_pos, 2 -- delete 'ä'
        assert.equal cur_length + 2, b.length

  describe 'undo', ->
    it 'undoes the last operation', ->
      b = Buffer 'hello'
      b\delete 1, 1
      b\undo!
      assert.equal 'hello', b.text

  describe '.can_undo', ->
    it 'returns true if there are any revisions to undo in the buffer', ->
      b = Buffer 'hello'
      assert.is_false b.can_undo
      b\insert 1, 'hola '
      assert.is_true b.can_undo

  describe 'as_one_undo(f)', ->
    it 'invokes <f>, grouping all modification as one undo', ->
      b = Buffer 'hello'
      b\as_one_undo ->
        b\insert 6, ' world'
        b\delete 1, 5
        b\insert 1, 'cruel'

      assert.equal 'cruel world', b.text
      b\undo!
      assert.equal 'hello', b.text

    it 'bubbles up any errors in <f>', ->
      b = Buffer 'hello'
      assert.raises 'BOOM', -> b\as_one_undo -> error 'BOOM'

  describe 'redo', ->
    it 'redoes the last undone operation', ->
      b = Buffer 'hello'
      b\delete 1, 1
      b\undo!
      b\redo!
      assert.equal 'ello', b.text

  describe 'refresh_styling_at(line_nr, to_line [, opts])', ->
    local b, styling, mode

    before_each ->
      b = Buffer ''
      mode = {}
      b.mode = mode

    context 'and <offset> is not part of a block', ->
      it 'refreshes only the current line', ->
        b.text = '123\n56\n89\n'
        b.lexer = spy.new -> { 1, 'operator', 2 }

        b.styling\apply 1, {
          1, 'keyword', 4,
          5, 'string', 7,
          8, 'string', 9,
        }

        b\refresh_styling_at 2, 3

        assert.spy(b.lexer).was_called_with '56\n'
        assert.same { 1, 'operator', 2 }, b.styling\get(5, 7)

      it 'falls back to a full lexing if newly lexed line is part of a block', ->
        b.text = '123\n56\n'

        lexers = {
          spy.new -> { 1, 'string', 5 },
          spy.new -> { 1, 'string', 7 },
        }
        call_count = 1
        b.lexer = (text) ->
          l = lexers[call_count]
          assert.is_not_nil l
          call_count += 1
          l(text)

        b\refresh_styling_at 1, 3

        assert.spy(lexers[1]).was_called_with '123\n'
        assert.spy(lexers[2]).was_called_with '123\n56\n'
        assert.same { 1, 'string', 7 }, b.styling\get(1, 7)

    context 'and <offset> is at the last line of a block', ->
      it 'starts from the first non-block line', ->
        b.text = '123\n56\n89\n'
        b.lexer = spy.new -> { 1, 'operator', 6 }

        b.styling\apply 1, {
          1, 'keyword', 4,
          5, 'string', 10, -- block of line 2 & 3
        }

        b\refresh_styling_at 3, 4

        assert.spy(b.lexer).was_called_with '56\n89\n'
        assert.same { 1, 'operator', 4 }, b.styling\get(5, 7)
        assert.same { 1, 'operator', 3 }, b.styling\get(8, 10)

    context 'and <offset> is at a line within a block', ->
      it 'only lexes up to the current line if the new styling ends in the same block style', ->
        b.text = '123\n56\n89\n'
        b.lexer = spy.new -> { 1, 'my_block', 8 }
        b.styling\set 1, 10, 'my_block'
        res = b\refresh_styling_at 2, 3
        assert.spy(b.lexer).was_called(1)
        assert.spy(b.lexer).was_called_with '123\n56\n'
        assert.same { start_line: 2, end_line: 2, invalidated: false }, res

      it 'lexes the full range if the new styling indicates a block change', ->
        b.text = '123\n56\n89\n'
        b.lexer = spy.new -> { 1, 'operator', 2 }
        b.styling\set 1, 10, 'my_block'
        res = b\refresh_styling_at 2, 3
        assert.spy(b.lexer).was_called(2)
        assert.spy(b.lexer).was_called_with '123\n56\n'
        assert.spy(b.lexer).was_called_with '123\n56\n89\n'
        assert.same { start_line: 2, end_line: 3, invalidated: true }, res

    it 'returns the styled range', ->
      b.text = '123\n56\n89\n'
      b.lexer = spy.new -> { 1, 'operator', 2 }
      res = b\refresh_styling_at 1, 3
      assert.same { start_line: 1, end_line: 1, invalidated: false }, res

    context 'when opts.force_full is set', ->
      it 'always lexes the full range', ->
        b.text = '123\n56\n89\n'
        b.lexer = spy.new -> { 1, 'operator', 2 }
        res = b\refresh_styling_at 1, 3, force_full: true
        assert.spy(b.lexer).was_called_with '123\n56\n89\n'
        assert.same { start_line: 1, end_line: 3, invalidated: true }, res

    context 'notifications', ->
      it 'fires the on_styled notification', ->
        listener = on_styled: spy.new ->
        b\add_listener listener
        b.text = '123\n56\n89\n'
        b.lexer = -> { 1, 'operator', 2 }
        b\refresh_styling_at 1, 3, force_full: true
        assert.spy(listener.on_styled).was_called 1
        assert.spy(listener.on_styled).was_called_with listener, b, {
          start_line: 1, end_line: 3, invalidated: true
        }

      it 'sets the start offset from the first affected line regardless of the lexing', ->
        b.text = '123\n56\n89\n'
        b.lexer = spy.new -> { 1, 'string', 7 }
        b.styling\set 1, 6, 'string' -- block from 1st to 2nd line
        res = b\refresh_styling_at 2, 3
        assert.spy(b.lexer).was_called_with '123\n56\n' -- both lines b.lexer due to block
        -- but only the second line is effectively restyled
        assert.same { start_line: 2, end_line: 2, invalidated: false }, res

    it 'supresses the on_styled notification if opts.no_notify is set', ->
      listener = on_styled: spy.new ->
      b\add_listener listener
      b.text = '123\n56\n89\n'
      b.lexer = -> { 1, 'operator', 2 }
      b\refresh_styling_at 1, 3, force_full: true, no_notify: true
      assert.spy(listener.on_styled).was_not_called!

    context 'when lexing the full range', ->
      before_each ->
        b.text = '123\n56\n89\n'
        b.styling\set 1, 10, 'keyword'

      it 'invalidates all subsequent styling', ->
        b.lexer = -> { 1, 'operator', 2 }
        res = b\refresh_styling_at 1, 2, force_full: true
        assert.same {}, b.styling\get(8, 10)

      it 'sets the styling last_pos_styled to the last line styled', ->
        b.lexer = -> { 1, 'operator', 2 }
        b\refresh_styling_at 1, 2, force_full: true
        assert.equals 7, b.styling.last_pos_styled

        b\refresh_styling_at 1, 3, force_full: true
        assert.equals 10, b.styling.last_pos_styled

  context 'meta methods', ->
    it 'tostring returns a lua string representation of the buffer', ->
      b = Buffer 'hello world'
      assert.equals 'hello world', tostring b

  context 'notifications', ->
    describe 'on_inserted', ->
      it 'is fired upon insertions to all interested listeners', ->
        l1 = on_inserted: spy.new -> nil
        l2 = on_inserted: spy.new -> nil
        b = Buffer 'hello'
        b\add_listener l1
        b\add_listener l2
        b\insert 3, 'xx'
        args = {
          offset: 3,
          text: 'xx',
          size: 2,
          invalidate_offset: 3,
          revision: b.revisions[1]
        }
        assert.spy(l1.on_inserted).was_called_with l1, b, args
        assert.spy(l2.on_inserted).was_called_with l2, b, args

    describe 'on_deleted', ->
      it 'is fired upon deletions to listeners', ->
        l1 = on_deleted: spy.new -> nil
        b = Buffer 'hello'
        b\add_listener l1
        b\delete 3, 2
        assert.spy(l1.on_deleted).was_called_with l1, b, {
          offset: 3,
          text: 'll',
          size: 2,
          invalidate_offset: 3,
          revision: b.revisions[1]
        }

    it 'fires on_styled notifications for styling changes outside of lexing', ->
      b = Buffer '12\n45'
      l = on_styled: spy.new -> nil
      b\add_listener l
      b.styling\set 1, 5, 'string'
      assert.spy(l.on_styled).was_called_with l, b, {
        start_line: 1,
        end_line: 2,
        invalidated: false
      }
