-- Copyright 2012-2014 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Cursor = require 'aullar.cursor'
View = require 'aullar.view'
Selection = require 'aullar.selection'
Buffer = require 'aullar.buffer'
Gtk = require 'ljglibs.gtk'

describe 'View', ->
  local view, buffer, cursor

  before_each ->
    buffer = Buffer ''
    view = View buffer
    cursor = view.cursor
    window = Gtk.OffscreenWindow default_width: 800, default_height: 640
    window\add view\to_gobject!
    window\show_all!
    pump_mainloop!

  context '(coordinate translation)', ->
    before_each -> view.margin = 0

    describe 'position_from_coordinates(x, y)', ->
      it 'returns the matching buffer position', ->
        dim = view\text_dimensions 'M'
        buffer.text = '1234\n6789'
        assert.equals 2, view\position_from_coordinates(view.edit_area_x + dim.width + 1, 0)
        assert.equals 8, view\position_from_coordinates(view.edit_area_x + (dim.width * 2) + 1, dim.height + 1)

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
        assert.same {
          x: view.edit_area_x + dim.width
          x2: view.edit_area_x + (dim.width * 2)
          y: 0
          y2: dim.height
        }, view\coordinates_from_position(2)

        assert.same {
          x: view.edit_area_x + (dim.width * 2)
          x2: view.edit_area_x + (dim.width * 3)
          y: dim.height
          y2: dim.height * 2
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

