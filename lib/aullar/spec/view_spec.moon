-- Copyright 2014 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Cursor = require 'aullar.cursor'
View = require 'aullar.view'
Selection = require 'aullar.selection'
Buffer = require 'aullar.buffer'
Gtk = require 'ljglibs.gtk'

describe 'View', ->
  local view, buffer, cursor, selection

  before_each ->
    buffer = Buffer ''
    view = View buffer
    cursor = view.cursor
    selection = view.selection
    window = Gtk.OffscreenWindow default_width: 800, default_height: 640
    window\add view\to_gobject!
    window\show_all!
    pump_mainloop!

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
        assert.equals math.ceil(nr_lines_in_screen / 2), view.middle_visible_line

      it 'scrolls the view to show the specified line in the center when set', ->
        view.middle_visible_line = nr_lines_in_screen
        assert.equals nr_lines_in_screen, view.middle_visible_line
        assert.equals math.ceil(nr_lines_in_screen / 2), view.first_visible_line

    describe '.last_visible_line', ->
      it 'is the last visible line', ->
        assert.equals math.floor(nr_lines_in_screen), view.last_visible_line

  context '(coordinate translation)', ->
    before_each -> view.margin = 0

    describe 'position_from_coordinates(x, y)', ->
      it 'returns the matching buffer position', ->
        dim = view\text_dimensions 'M'
        buffer.text = '1234\n6789'
        line_height = view.display_lines[1].height
        assert.equals 2, view\position_from_coordinates(view.edit_area_x + dim.width + 1, 0)
        assert.equals 8, view\position_from_coordinates(view.edit_area_x + (dim.width * 2) + 1, line_height + 1)

      it 'favours the preceeding character slightly when in doubt', ->
        dim = view\text_dimensions 'M'
        buffer.text = '1234'
        assert.equals 1, view\position_from_coordinates(view.edit_area_x + dim.width / 2, 0)
        assert.equals 1, view\position_from_coordinates(view.edit_area_x + dim.width * 0.6, 0)
        assert.equals 2, view\position_from_coordinates(view.edit_area_x + dim.width * 0.8, 0)

      it 'returns nil for out of bounds coordinates', ->
        assert.is_nil view\position_from_coordinates(100, 100)

    describe 'coordinates_from_position(pos)', ->
      it 'returns the bounding rectangle for the character at pos', ->
        dim = view\text_dimensions 'M'
        buffer.text = '1234\n6789'
        line_height = view.display_lines[1].height
        assert.same {
          x: view.edit_area_x + dim.width
          x2: view.edit_area_x + (dim.width * 2)
          y: 0
          y2: dim.height
        }, view\coordinates_from_position(2)

        assert.same {
          x: view.edit_area_x + (dim.width * 2)
          x2: view.edit_area_x + (dim.width * 3)
          y: line_height
          y2: line_height + dim.height
        }, view\coordinates_from_position(8)

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
