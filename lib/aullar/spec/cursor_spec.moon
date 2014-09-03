-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Cursor = require 'aullar.cursor'
View = require 'aullar.view'
Selection = require 'aullar.selection'
Buffer = require 'aullar.buffer'
Gtk = require 'ljglibs.gtk'

describe 'Cursor', ->
  local view, buffer, cursor

  before_each ->
    buffer = Buffer ''
    view = View buffer
    cursor = view.cursor
    window = Gtk.OffscreenWindow default_width: 800, default_height: 640
    window\add view\to_gobject!
    window\show_all!
    pump_mainloop!

  it 'starts at out pos 1, line 1', ->
    assert.equals 1, cursor.pos
    assert.equals 1, cursor.line

  describe 'forward()', ->
    it 'moves the cursor one character forward', ->
      buffer.text = 'åäö'
      cursor\forward!
      assert.equals 3, cursor.pos -- 'å' is two bytes

    it 'moves to the next line if needed', ->
      buffer.text = 'å\nnext'
      cursor\forward!
      cursor\forward!
      assert.equals 2, cursor.line

  describe 'backward()', ->
    it 'moves the cursor one character backwards', ->
      buffer.text = 'åäö'
      cursor.pos = 5 -- at 'ö'
      cursor\backward!
      assert.equals 3, cursor.pos

  describe 'up()', ->
    it 'moves the cursor one line up', ->
      buffer.text = 'line 1\nline 2'
      cursor.pos = 8
      cursor\up!
      assert.equals 1, cursor.line

    it 'does nothing if the cursor is at the first line', ->
      buffer.text = 'line 1\nline 2'
      cursor\up!
      assert.equals 1, cursor.pos

  describe 'down()', ->
    it 'moves the cursor one line down', ->
      buffer.text = 'line 1\nline 2'
      cursor\down!
      assert.equals 2, cursor.line

    it 'does nothing if the cursor is at the last line', ->
      buffer.text = 'line 1\nline 2'
      cursor.pos = 8
      cursor\down!
      assert.equals 8, cursor.pos
