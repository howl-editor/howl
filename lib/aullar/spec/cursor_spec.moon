-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

View = require 'aullar.view'
Buffer = require 'aullar.buffer'

describe 'Cursor', ->
  local view, buffer, cursor, selection

  before_each ->
    buffer = Buffer ''
    view = View buffer
    cursor = view.cursor
    selection = view.selection
    test_window view\to_gobject!

  describe '.style', ->
    it 'is "line" by default', ->
      assert.equal 'line', cursor.style

    it 'raises an error if set to anything else than "block" or "line"', ->
      cursor.style = 'block'
      cursor.style = 'line'
      assert.raises 'foo', -> cursor.style = 'foo'

  describe 'move_to(opts)', ->
    describe 'when opts.pos is specified', ->
      it 'moves the cursor to the specified positio', ->
        buffer.text = '1\n3\n5'
        cursor\move_to pos: 3
        assert.equals 3, cursor.pos
        cursor\move_to pos: 5
        assert.equals 5, cursor.pos

      it 'does not allow to move into the middle of a EOL', ->
        buffer.text = '12\r\n'
        cursor.pos = 1
        cursor\move_to pos: 3
        assert.equals 3, cursor.pos

        cursor\move_to pos: 4
        assert.equals 3, cursor.pos

      it 'does not allow to move into the middle of multibyte characters', ->
        buffer.text = '1å\n' -- å being two bytes long
        cursor\move_to pos: 3
        assert.equals 4, cursor.pos

    describe 'when opts.line is specified', ->
      it 'moves the cursor to the first column of that line', ->
        buffer.text = '1\n3\n5'
        cursor\move_to line: 2
        assert.equals 3, cursor.pos
        cursor\move_to line: 3
        assert.equals 5, cursor.pos

      it 'moves to column specified by opts.column if given', ->
        buffer.text = '1\n3r4\n6'
        cursor\move_to line: 2, column: 2
        assert.equals 4, cursor.pos

      it 'does not allow to move into the middle of multibyte characters', ->
        buffer.text = '1å\n' -- å being two bytes long
        cursor\move_to line: 1, column: 3
        assert.equals 4, cursor.pos

  describe 'forward()', ->
    it 'moves the cursor one character forward', ->
      buffer.text = 'åäö'
      cursor.pos = 1
      cursor\forward!
      assert.equals 3, cursor.pos -- 'å' is two bytes

    it 'handles forwarding over the eof correctly', ->
      buffer.text = 'x\n'
      cursor.pos = 2
      cursor\forward!
      assert.equals 3, cursor.pos
      cursor\forward!
      assert.equals 3, cursor.pos

      buffer.text = 'x'
      cursor.pos = 1
      cursor\forward!
      assert.equals 2, cursor.pos
      cursor\forward!
      assert.equals 2, cursor.pos

      -- CRLF
      buffer.text = '1\r\n4'
      cursor.pos = 2
      cursor\forward!
      assert.equals 2, cursor.line
      assert.equals 1, cursor.column
      assert.equals 4, cursor.pos

    it 'moves to the next line if needed', ->
      buffer.text = 'å\nnext'
      cursor.pos = 1
      cursor\forward!
      cursor\forward!
      assert.equals 2, cursor.line

    context 'when a selection is present', ->
      it 'moves the cursor to the end of the selection and clears it', ->
        buffer.text = '12345678'
        cursor.pos = 2
        selection\set 5, 2
        assert.equals 2, cursor.pos
        cursor\forward!
        assert.equals 5, cursor.pos
        assert.is_true selection.is_empty

      it 'extends the selection if it is persistent', ->
        buffer.text = '12345678'
        cursor.pos = 1
        selection.persistent = true
        cursor\forward!
        assert.equals 2, cursor.pos
        assert.same {1, 2}, {selection\range!}
        cursor\forward!
        assert.same {1, 3}, {selection\range!}

  describe 'backward()', ->
    it 'moves the cursor one character backwards', ->
      buffer.text = 'åäö'
      cursor.pos = 5 -- at 'ö'
      cursor\backward!
      assert.equals 3, cursor.pos

    it 'moves back to the previous line as needed', ->
      buffer.text = 'x\n'
      cursor.pos = 3
      cursor\backward!
      assert.equals 2, cursor.pos
      cursor\backward!
      assert.equals 1, cursor.pos

      -- CRLF
      buffer.text = '1\r\n4'
      cursor.pos = 4
      cursor\backward!
      assert.equals 1, cursor.line
      assert.equals 2, cursor.column
      assert.equals 2, cursor.pos

    context 'when a selection is present', ->
      it 'moves the cursor to the start of the selection and clears it', ->
        buffer.text = '12345678'
        cursor.pos = 5
        selection\set 2, 5
        assert.equals 5, cursor.pos
        cursor\backward!
        assert.equals 2, cursor.pos
        assert.is_true selection.is_empty

      it 'extends the selection if it is persistent', ->
        buffer.text = '12345678'
        cursor.pos = 6
        selection.persistent = true
        cursor\backward!
        assert.equals 5, cursor.pos
        assert.same {5, 6}, {selection\range!}
        cursor\backward!
        assert.same {4, 6}, {selection\range!}

  describe 'up()', ->
    it 'moves the cursor one line up', ->
      buffer.text = 'line 1\nline 2'
      cursor.pos = 8
      cursor\up!
      assert.equals 1, cursor.line

    it 'does nothing if the cursor is at the first line', ->
      buffer.text = 'line 1\nline 2'
      cursor.pos = 1
      cursor\up!
      assert.equals 1, cursor.pos

    it 'does not move into the middle of a EOL', ->
      buffer.text = '12\r\n123'
      cursor.pos = 8
      cursor\up!
      assert.equals 3, cursor.pos

    it 'respects the remembered column', ->
      buffer.text = '12345\n12\n1234'
      cursor.line = 3
      cursor.column = 4
      cursor\remember_column!

      cursor\up!
      assert.equal 2, cursor.line
      assert.equal 3, cursor.column

      cursor\up!
      assert.equal 1, cursor.line
      assert.equal 4, cursor.column

  describe 'down()', ->
    it 'moves the cursor one line down', ->
      buffer.text = 'line 1\nline 2'
      cursor.pos = 1
      cursor\down!
      assert.equals 2, cursor.line

    it 'does nothing if the cursor is at the last line', ->
      buffer.text = 'line 1\nline 2'
      cursor.pos = 8
      cursor\down!
      assert.equals 8, cursor.pos

    it 'respects the remembered column', ->
      buffer.text = '12345\n12\n1234'
      cursor.pos = 4
      cursor\remember_column!

      cursor\down!
      assert.equal 2, cursor.line
      assert.equal 3, cursor.column

      cursor\down!
      assert.equal 3, cursor.line
      assert.equal 4, cursor.column

    it 'does not move into the middle of a EOL', ->
      buffer.text = '123\r\n67\r\n'
      cursor.pos = 4
      cursor\down!
      assert.equals 8, cursor.pos

  describe 'when the selection is marked as persistent', ->
    it 'is updated as part of cursor movement', ->
      buffer.text = '12345678'
      cursor.pos = 4
      selection\set 2, 4
      selection.persistent = true
      cursor\forward!
      assert.equal 5, selection.end_pos
      cursor.pos = 1
      assert.equal 1, selection.end_pos

  describe 'when .listener is set', ->
    it 'calls listener.on_pos_changed with (listener, cursor) when moved', ->
      buffer.text = '12345'
      cursor.pos = 1
      on_pos_changed = spy.new -> nil
      cursor.listener = :on_pos_changed
      cursor.pos = 3
      assert.spy(on_pos_changed).was_called_with(cursor.listener, cursor)
