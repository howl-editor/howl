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

