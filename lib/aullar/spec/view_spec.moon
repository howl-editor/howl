-- Copyright 2014 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

View = require 'aullar.view'
Buffer = require 'aullar.buffer'

describe 'View', ->
  local view, buffer, cursor, selection

  before_each ->
    buffer = Buffer ''
    view = View buffer
    view.config.view_line_padding = 0
    cursor = view.cursor
    selection = view.selection
    test_window view\to_gobject!

  context 'visible line orientation properties', ->
    local nr_lines_in_screen

    before_each ->
      line_height = view.display_lines[1].height
      nr_lines_in_screen = math.floor view.height / line_height
      buffer.text = string.rep '123456789\n', nr_lines_in_screen * 3
      view.first_visible_line = 1

    describe '.first_visible_line', ->
      it 'is the first visible line', ->
        assert.equals 1, view.first_visible_line
        view\scroll_to 10
        assert.equals 10, view.first_visible_line

    describe '.middle_visible_line', ->
      it 'is the center vertical line', ->
        assert.is_near nr_lines_in_screen / 2, view.middle_visible_line, 1

      it 'scrolls the view to show the specified line in the center when set', ->
        view.middle_visible_line = nr_lines_in_screen
        assert.equals nr_lines_in_screen, view.middle_visible_line
        assert.is_near (nr_lines_in_screen / 2), view.first_visible_line, 1

    describe '.last_visible_line', ->
      it 'is the last visible line', ->
        assert.equals nr_lines_in_screen, view.last_visible_line

  context '(coordinate translation)', ->
    local dim

    before_each ->
      dim = view\text_dimensions 'M'

    describe 'position_from_coordinates(x, y, opts = {})', ->
      it 'returns the matching buffer position', ->
        buffer.text = '1234\n67890'
        line_height = view.display_lines[1].height
        assert.equals 2, view\position_from_coordinates(dim.width + 1, 0)
        assert.equals 8, view\position_from_coordinates((dim.width * 2) + 1, line_height + 1)

      it 'favours the preceeding character slightly when in doubt', ->
        buffer.text = '1234'
        assert.equals 1, view\position_from_coordinates(dim.width / 2, 0)
        assert.equals 1, view\position_from_coordinates(dim.width * 0.6, 0)
        assert.equals 2, view\position_from_coordinates(dim.width * 0.8, 0)

      it 'returns nil for out of bounds coordinates', ->
        assert.is_nil view\position_from_coordinates(100, 100)

      it 'returns the position of the end-of-line when outside to the right', ->
        buffer.text = '1234\n6789'
        assert.equals 5, view\position_from_coordinates(dim.width * 6, 0)

      it 'returns the position of the start-of-line when outside to the left', ->
        buffer.text = '1234\n6789'
        assert.equals 1, view\position_from_coordinates(-1, 0)
        line_height = view.display_lines[1].height
        assert.equals 6, view\position_from_coordinates(-1, line_height + 1)

      it 'returns the correct position when in the line padding', ->
        view.config.view_line_padding = 4
        buffer.text = '1234'
        assert.equals 3, view\position_from_coordinates(dim.width * 2, 0)
        line_height = view.display_lines[1].height
        assert.equals 3, view\position_from_coordinates(dim.width * 2, line_height - 1)

      context 'when opts.fuzzy is set', ->
        it 'returns the closest position in the last line', ->
          buffer.text = '1234\n6789'
          line_height = view.display_lines[1].height
          assert.equals 8, view\position_from_coordinates(
            (dim.width * 2) + 1,
            (line_height * 2) + 1,
            fuzzy: true
          )

  describe '(when text is inserted)', ->
    it 'moves the cursor down if the insertion is before or at the cursor', ->
      buffer\insert 1, '123'
      assert.equals 4, cursor.pos
      buffer\insert 3, 'X'
      assert.equals 5, cursor.pos

    it 'leaves the cursor alone if the insertion is after the cursor', ->
      buffer.text = '123'
      cursor.pos = 2
      buffer\insert 3, 'X'
      assert.equals 2, cursor.pos

  describe '(when text is deleted)', ->
    it 'moves the cursor up if the deletetion is before the cursor', ->
      buffer.text = '12345'
      cursor.pos = 4
      buffer\delete 3, 1
      assert.equals 3, cursor.pos

    it 'leaves the cursor alone if the deletetion is after or at the cursor', ->
      buffer.text = '12345'
      cursor.pos = 3
      buffer\delete 4, 1
      assert.equals 3, cursor.pos
      buffer\delete 3, 1
      assert.equals 3, cursor.pos

    it 'only adjust the cursor by the affected amount', ->
      buffer.text = '12345'
      cursor.pos = 3
      buffer\delete 2, 3
      assert.equals 2, cursor.pos

      buffer.text = '123456789'
      cursor.pos = 8
      buffer\delete 2, 3
      assert.equals 5, cursor.pos

  describe '(when text is changed)', ->
    it 'moves the cursor up for contracting changes before the cursor', ->
      buffer.text = '12345'
      cursor.pos = 4
      buffer\change 1, 3, (b) ->
        b\delete 1, 3
        b\insert 1, 'X'

      assert.equals 2, cursor.pos

    it 'moves the cursor up for expanding changes before the cursor', ->
      buffer.text = '12345'
      cursor.pos = 4
      buffer\change 1, 3, (b) ->
        b\delete 3, 1
        b\insert 1, 'XX'

      assert.equals 5, cursor.pos

    it 'handles changes over the cursor position', ->
      buffer.text = '12345'
      cursor.pos = 3
      buffer\change 1, 5, (b) ->
        b\delete 2, 3 -- down to 2
        b\insert 1, 'XXXX' -- up to 6
        b\delete 1, 1 -- down to 5

      assert.equals 5, cursor.pos

    it 'leaves the cursor alone for changes after the cursor position', ->
      buffer.text = '12345'
      cursor.pos = 2
      buffer\change 1, 5, (b) ->
        b\delete 2, 1
        b\insert 3, 'XXX'
        b\delete 3, 1

      assert.equals 2, cursor.pos

  describe 'when a buffer operation is undone', ->
    it 'moves the cursor to the position before action', ->
      buffer.text = '12345'
      cursor.pos = 2
      buffer\delete 4, 1
      cursor.pos = 1
      buffer\undo!
      assert.equals 2, cursor.pos

    it 'restores the selection', ->
      buffer.text = '12345'
      cursor.pos = 2
      selection\set 5, 2
      view\delete_back!
      buffer\undo!
      assert.equals 5, selection.anchor
      assert.equals 2, selection.end_pos
      assert.equals 2, cursor.pos

  describe 'when a buffer operation is redone', ->
    it 'moves the cursor to the position after the action', ->
      buffer.text = '12345'
      cursor.pos = 2
      buffer\insert 2, 'xx'
      assert.equals 4, cursor.pos
      buffer\undo!
      assert.equals 2, cursor.pos
      buffer\redo!
      assert.equals 4, cursor.pos

  context '.last_edit_pos', ->
    it 'is nil by default', ->
      assert.is_nil view.last_edit_pos

    it 'is updated when text is inserted at the cursor', ->
      buffer.text = '123456'
      cursor.pos = 4
      view\insert 'x'
      assert.equals 5, view.last_edit_pos

    it 'is updated when deleting back', ->
      buffer.text = '123456'
      cursor.pos = 4
      view\delete_back!
      assert.equals 3, view.last_edit_pos

    it 'is reset when buffers are changed', ->
      view\insert 'x'
      assert.equals 2, view.last_edit_pos
      view.buffer = Buffer!
      assert.is_nil view.last_edit_pos

    it 'is not updated by cursor movements', ->
      view.buffer = Buffer '123456'
      assert.is_nil view.last_edit_pos
      cursor.pos = 4
      assert.is_nil view.last_edit_pos

    context '(for other modifications)', ->
      it 'is updated when the view is focused', ->
        buf = Buffer '123456'
        view.buffer = buf
        assert.is_nil view.last_edit_pos
        cursor.pos = 1
        buf\insert 1, 'x'
        assert.equals 2, view.last_edit_pos
        buf\delete 1, 1
        assert.equals 1, view.last_edit_pos

      it 'is not updated for unfocused views', ->
        buf = Buffer '123456'
        v = View buf
        assert.is_nil v.last_edit_pos
        cursor.pos = 1
        buf\insert 1, 'x'
        assert.is_nil view.last_edit_pos
        buf\delete 1, 1
        assert.is_nil view.last_edit_pos

  context 'resource management', ->

    it 'references are collected properly', ->
      v = View!
      views = setmetatable { v }, __mode: 'v'
      v\destroy!
      v = nil
      collect_memory!
      collect_memory!
      assert.is_true views[1] == nil
