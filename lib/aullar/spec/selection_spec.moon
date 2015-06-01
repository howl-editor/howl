-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

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

  describe '.size', ->
    it 'is zero for an empty selection', ->
      assert.equals 0, selection.size

    it 'is the number of bytes selected', ->
      buffer.text = '123456789'
      selection\set 2, 6
      assert.equals 4, selection.size

    it 'reports the size correctly for backward selection', ->
      buffer.text = '123456789'
      selection\set 6, 2
      assert.equals 4, selection.size

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
    it 'is {nil, nil} for an empty selection', ->
      assert.same {nil, nil}, { selection\range! }

    it 'returns the start and stop position, in ascending order', ->
      selection\set 2, 4
      assert.same { 2, 4 }, { selection\range! }
      selection\set 4, 2
      assert.same { 2, 4 }, { selection\range! }
