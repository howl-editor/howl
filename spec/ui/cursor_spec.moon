import Gtk from lgi
import Buffer from howl
import Editor, theme from howl.ui

text = [[
Line 1 of text
And here's line two
And finally a third line
]]

describe 'Cursor', ->
  buffer = Buffer {}
  buffer.text = text
  editor = Editor buffer
  cursor = editor.cursor
  selection = editor.selection

  before_each -> selection.persistent = false

  describe '.style', ->
    it 'is "line" by default', ->
      assert.equal 'line', cursor.style

    it 'raises an error if set to anything else than "block" or "line"', ->
      cursor.style = 'block'
      cursor.style = 'line'
      assert.raises 'foo', -> cursor.style = 'foo'

  describe '.pos', ->
    it 'reading returns the current position in one based index', ->
      editor.sci\goto_pos 0
      assert.equal cursor.pos, 1

    it 'setting sets the current position', ->
      cursor.pos = 4
      assert.equal cursor.pos, 4

    it 'setting adjusts the selection if it is persistent', ->
      selection\set 1, 2
      selection.persistent = true
      cursor.pos = 5
      assert.equal cursor.pos, 5
      assert.equals 'Line', selection.text

  describe '.line', ->
    it 'returns the current line', ->
      cursor.pos = 1
      assert.equal cursor.line, 1

    it 'setting moves the cursor to the first column of the specified line', ->
      cursor.line = 2
      assert.equal cursor.pos, 16

    it 'assignment adjusts out-of-bounds values automatically', ->
      cursor.line = -1
      assert.equal 1, cursor.pos
      cursor.line = 100
      assert.equal #buffer + 1, cursor.pos

    it 'assignment adjusts the selection if it is persistent', ->
      cursor.pos = 1
      selection.persistent = true
      cursor.line = 2
      assert.equals 'Line 1 of text\n', selection.text

  describe '.column', ->
    it 'returns the current column', ->
      cursor.pos = 4
      assert.equal cursor.column, 4

    it 'setting moves the cursor to the specified column', ->
      cursor.column = 2
      assert.equal cursor.pos, 2

    it 'setting adjusts the selection if it is persistent', ->
      cursor.pos = 1
      selection.persistent = true
      cursor.column = 2
      assert.equals 'L', selection.text

  it '.at_end_of_line returns true if cursor is at the end of the line', ->
    cursor.pos = 1
    assert.is_false cursor.at_end_of_line
    cursor.column = 15
    assert.is_true cursor.at_end_of_line

  it 'down! moves the cursor one line down, respecting the current column', ->
    cursor.pos = 4
    cursor\down!
    assert.equal cursor.line, 2
    assert.equal cursor.column, 4

  it 'up! moves the cursor one line down, respecting the current column', ->
    cursor.line = 2
    cursor.column = 3
    cursor\up!
    assert.equal cursor.line, 1
    assert.equal cursor.column, 3

  it 'right! moves the cursor one char right', ->
    cursor.pos = 1
    cursor\right!
    assert.equal cursor.pos, 2

  it 'left! moves the cursor one char left', ->
    cursor.pos = 3
    cursor\left!
    assert.equal cursor.pos, 2

  context 'when passing true for extended_selection to movement commands', ->
    it 'the selection is extended along with moving the cursor', ->
      sel = editor.selection
      cursor.pos = 1
      cursor\right true
      assert.equal sel.text, 'L'
      cursor\down true
      assert.equal sel.text, 'Line 1 of text\nA'
      cursor\left true
      assert.equal sel.text, 'Line 1 of text\n'
      cursor\up true
      assert.is_true sel.empty

  context 'when the editor selection is marked as persistent', ->
    it 'the selection is extended along with moving the cursor', ->
      sel = editor.selection
      sel.persistent = true
      cursor.pos = 1
      cursor\right!
      assert.equal sel.text, 'L'
      cursor.line = 2
      assert.equal sel.text, 'Line 1 of text\n'
