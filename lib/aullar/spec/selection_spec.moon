-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Selection = require 'aullar.selection'
View = require 'aullar.view'
Buffer = require 'aullar.buffer'

describe 'Selection', ->
  local view, buffer, selection

  before_each ->
    buffer = Buffer ''
    view = View buffer
    selection = Selection view

  it 'starts at out empty', ->
    assert.is_true selection.is_empty

  describe 'affects_line(line)', ->
    line = (nr) -> buffer\get_line nr

    before_each ->
      buffer.text = 'line 1\nline 2\nline 3\nline 4\nline 5'
      anchor = line(2).start_offset + 3
      end_pos = line(4).start_offset + 3
      selection\set anchor, end_pos

    it 'returns true if the selection starts at, encompasses, or ends at line', ->
      assert.is_false selection\affects_line line 1
      assert.is_true selection\affects_line line 2
      assert.is_true selection\affects_line line 3
      assert.is_true selection\affects_line line 4
      assert.is_false selection\affects_line line  5

  describe 'extend(from, to)', ->
    context 'with no prior selection', ->
      it 'sets the selection using from and to', ->
        buffer.text = 'foobar'
        selection\extend 3, 4
        assert.equals 3, selection.anchor
        assert.equals 4, selection.end_pos

    context 'with a prior selection', ->
      it 'extends the selection from anchor, making <to> the new end pos', ->
        buffer.text = 'foobar urk'
        selection\set 2, 4
        selection\extend 4, 5
        assert.same { 2, 5 }, { selection.anchor, selection.end_pos }
        selection\extend 5, 1
        assert.same { 2, 1 }, { selection.anchor, selection.end_pos }

  describe 'range()', ->
    it 'returns the start and stop position, in ascending order', ->
      selection\set 2, 4
      assert.same { 2, 4 }, { selection\range! }
      selection\set 4, 2
      assert.same { 2, 4 }, { selection\range! }

  -- describe 'forward()', ->
  --   it 'moves the cursor one character forward', ->
  --     buffer.text = 'åäö'
  --     cursor\forward!
  --     assert.equals 3, cursor.pos -- 'å' is two bytes

  -- describe 'backward()', ->
  --   it 'moves the cursor one character backwards', ->
  --     buffer.text = 'åäö'
  --     cursor.pos = 5 -- at 'ö'
  --     cursor\backward!
  --     assert.equals 3, cursor.pos

  -- describe 'up()', ->
  --   it 'moves the cursor one line up', ->
  --     buffer.text = 'line 1\nline 2'
  --     cursor.pos = 8
  --     cursor\up!
  --     assert.equals 1, cursor.line

  --   it 'does nothing if the cursor is at the first line', ->
  --     buffer.text = 'line 1\nline 2'
  --     cursor\up!
  --     assert.equals 1, cursor.pos

  -- describe 'down()', ->
  --   it 'moves the cursor one line down', ->
  --     buffer.text = 'line 1\nline 2'
  --     cursor\down!
  --     assert.equals 2, cursor.line

  --   it 'does nothing if the cursor is at the last line', ->
  --     buffer.text = 'line 1\nline 2'
  --     cursor.pos = 8
  --     cursor\down!
  --     assert.equals 8, cursor.pos
