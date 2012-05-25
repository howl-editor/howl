import Gtk from lgi
import Buffer from vilu
import TextView, theme from vilu.ui

text = [[
Line 1 of text
And here's line two
And finally a third line
]]

describe 'Cursor', ->
  buffer = Buffer {}
  buffer.text = text
  view = TextView buffer
  cursor = view.cursor

  describe '.pos', ->
    it 'reading returns the current position', ->
      assert_equal cursor.pos, 1

    it 'setting sets the current position', ->
      cursor.pos = 4
      assert_equal cursor.pos, 4

  describe '.line', ->
    it 'returns the current line', ->
      cursor.pos = 1
      assert_equal cursor.line, 1

    it 'setting moves the cursor to the first column of the specified line', ->
      cursor.line = 2
      assert_equal cursor.pos, 16

  describe '.column', ->
    it 'returns the current column', ->
      cursor.pos = 4
      assert_equal cursor.column, 4

    it 'setting moves the cursor to the specified column', ->
      cursor.column = 2
      assert_equal cursor.pos, 2

  it 'down! moves the cursor one line down, respecting the current column', ->
    cursor.pos = 4
    cursor\down!
    assert_equal cursor.line, 2
    assert_equal cursor.column, 4

  it 'up! moves the cursor one line down, respecting the current column', ->
    cursor.line = 2
    cursor.column = 3
    cursor\up!
    assert_equal cursor.line, 1
    assert_equal cursor.column, 3

  it 'right! moves the cursor one char right', ->
    cursor.pos = 1
    cursor\right!
    assert_equal cursor.pos, 2

  it 'left! moves the cursor one char left', ->
    cursor.pos = 3
    cursor\left!
    assert_equal cursor.pos, 2
