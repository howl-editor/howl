import Buffer, config from howl
import Editor, theme from howl.ui

text = [[
Liñe 1 ʘf tƏxt
And hƏre's line twʘ
And finally a ƫhird line
]]

describe 'Cursor', ->
  buffer = Buffer {}
  editor = Editor buffer
  cursor = editor.cursor
  selection = editor.selection

  before_each ->
    buffer.text = text
    cursor.pos = 1
    selection.persistent = false

  describe '.style', ->
    it 'is "line" by default', ->
      assert.equal 'line', cursor.style

    it 'raises an error if set to anything else than "block" or "line"', ->
      cursor.style = 'block'
      cursor.style = 'line'
      assert.raises 'foo', -> cursor.style = 'foo'

  describe '.pos', ->
    it 'reading returns the current character position in one based index', ->
      editor.sci\goto_pos 4 -- raw zero-based sci access, really at 'e'
      assert.equal 4, cursor.pos

    it 'setting sets the current position', ->
      cursor.pos = 4
      assert.equal cursor.pos, 4

    it 'setting adjusts the selection if it is persistent', ->
      selection\set 1, 2
      selection.persistent = true
      cursor.pos = 5
      assert.equal cursor.pos, 5
      assert.equals 'Liñe', selection.text

    it 'out-of-bounds values are automatically corrected', ->
      cursor.pos = 0
      assert.equal 1, cursor.pos
      cursor.pos = -1
      assert.equal 1, cursor.pos
      cursor.pos = math.huge
      assert.equal #buffer + 1, cursor.pos
      cursor.pos = #buffer + 2
      assert.equal #buffer + 1, cursor.pos

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
      assert.equals 'Liñe 1 ʘf tƏxt\n', selection.text

  describe '.column', ->
    it 'returns the current column', ->
      cursor.pos = 4
      assert.equal cursor.column, 4

  describe '.column = <nr>', ->
    it 'moves the cursor to the specified column', ->
      cursor.column = 2
      assert.equal 2, cursor.pos

    it 'takes tabs into account', ->
      buffer.config.tab_width = 4
      buffer.text = '\tsome text after'
      cursor.pos = 1
      cursor.column = 5
      assert.equal 2, cursor.pos

    it 'adjusts the selection if it is persistent', ->
      cursor.pos = 1
      selection.persistent = true
      cursor.column = 5
      assert.equals 'Liñe', selection.text

  describe '.column_index', ->
    it 'returns the real column index for the current line disregarding tabs', ->
        buffer.config.tab_width = 4
        buffer.text = '\tsome text'
        cursor.pos = 2
        assert.equal 5, cursor.column
        assert.equal 2, cursor.column_index

    it 'returns the column index as a character offset', ->
        buffer.text = 'åäö\nåäö'
        cursor.pos = 6
        assert.equal 2, cursor.column_index

    it 'adjusts the selection if it is persistent', ->
      buffer.text = 'åäö'
      cursor.pos = 1
      selection.persistent = true
      cursor.column_index = 3
      assert.equals 'åä', selection.text

  describe '.column_index = <nr>', ->
    before_each ->
      buffer.config.tab_width = 4
      buffer.text = '\tsome text after'

    it 'moves the cursor to the specified column index', ->
      cursor.column_index = 2
      assert.equal 2, cursor.column_index
      assert.equal 5, cursor.column

    it 'treats <nr> as a character offset', ->
      buffer.text = 'åäö\nåäö'
      cursor.line = 2
      cursor.column_index = 2
      assert.equal 2, cursor.column_index
      assert.equal 6, cursor.pos

  it '.at_end_of_line returns true if cursor is at the end of the line', ->
    cursor.pos = 1
    assert.is_false cursor.at_end_of_line
    cursor.column = 15
    assert.is_true cursor.at_end_of_line

  it '.at_start_of_line returns true if cursor is at the start of the line', ->
    cursor.pos = 1
    assert.is_true cursor.at_start_of_line
    cursor.line = 2
    assert.is_true cursor.at_start_of_line

  it '.at_end_of_file returns true if cursor is at the end of the buffer', ->
    cursor.pos = 1
    assert.is_false cursor.at_end_of_file
    cursor\eof!
    assert.is_true cursor.at_end_of_file

  it 'move_to(line, column) moves the cursor to the specified line and column', ->
    buffer.text = 'hello\nworld'
    cursor\move_to 1, 3
    assert.equal 3, cursor.pos
    cursor\move_to 2, 2
    assert.equal 8, cursor.pos

  it 'down! moves the cursor one line down, respecting the current column', ->
    cursor.pos = 4
    cursor\down!
    assert.equal 2, cursor.line
    assert.equal 4, cursor.column

  it 'up! moves the cursor one line up, respecting the current column', ->
    cursor.line = 2
    cursor.column = 3
    cursor\up!
    assert.equal 1, cursor.line
    assert.equal 3, cursor.column

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
      assert.equal 'L', sel.text
      cursor\down true
      assert.equals 'Liñe 1 ʘf tƏxt\nA', sel.text
      cursor\left true
      assert.equals 'Liñe 1 ʘf tƏxt\n', sel.text
      cursor\up true
      assert.is_true sel.empty

  context 'when the editor selection is marked as persistent', ->
    it 'the selection is extended along with moving the cursor', ->
      sel = editor.selection
      sel.persistent = true
      cursor.pos = 1
      cursor\right!
      assert.equal 'L', sel.text
      cursor.line = 2
      assert.equals 'Liñe 1 ʘf tƏxt\n', sel.text
