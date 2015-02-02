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

  describe '.style', ->
    it 'is "line" by default', ->
      assert.equal 'line', cursor.style

    it 'raises an error if set to anything else than "block" or "line"', ->
      cursor.style = 'block'
      cursor.style = 'line'
      assert.raises 'foo', -> cursor.style = 'foo'

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

    it 'moves to the next line if needed', ->
      buffer.text = 'å\nnext'
      cursor.pos = 1
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
      cursor.pos = 1
      cursor\up!
      assert.equals 1, cursor.pos

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

  describe 'when .listener is set', ->
    it 'calls listener.on_pos_changed with (listener, cursor) when moved', ->
      buffer.text = '12345'
      cursor.pos = 1
      on_pos_changed = spy.new -> nil
      cursor.listener = :on_pos_changed
      cursor.pos = 3
      assert.spy(on_pos_changed).was_called_with(cursor.listener, cursor)
