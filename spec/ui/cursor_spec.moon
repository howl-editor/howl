import Buffer from howl
import Editor from howl.ui
Gtk = require 'ljglibs.gtk'

describe 'Cursor', ->
  buffer = Buffer {}
  editor = Editor buffer
  cursor = editor.cursor
  selection = editor.selection
  window = Gtk.OffscreenWindow default_width: 800, default_height: 640
  window\add editor\to_gobject!
  window\show_all!
  pump_mainloop!

  before_each ->
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
    before_each ->
      buffer.text = 'Liñe 1 ʘf tƏxt'

    it 'reading returns the current character position in one based index', ->
      editor.view.cursor.pos = 5 -- raw aullar access, really at 'e'
      assert.equal 4, cursor.pos

    it 'setting sets the current position', ->
      cursor.pos = 4
      assert.equal cursor.pos, 4

    it 'setting adjusts the selection if it is persistent', ->
      selection\set 1, 2
      selection.persistent = true
      cursor.pos = 5
      assert.equal 5, cursor.pos
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
    before_each ->
      buffer.text = [[
Liñe 1 ʘf tƏxt
And hƏre's line twʘ
]]

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
      buffer.text = 'Liñe 1 ʘf tƏxt'
      cursor.pos = 4
      assert.equal cursor.column, 4

    it 'takes tabs into account', ->
      buffer.config.tab_width = 4
      buffer.text = '\tsome text after'
      cursor.pos = 2
      assert.equal 5, cursor.column

  describe '.column = <nr>', ->
    it 'moves the cursor to the specified column', ->
      buffer.text = 'Liñe 1 ʘf tƏxt'
      cursor.column = 4
      assert.equal 4, cursor.pos

      cursor.column = 1
      assert.equal 1, cursor.pos

    it 'takes tabs into account', ->
      buffer.config.tab_width = 4
      buffer.text = '\tsome text after'
      cursor.pos = 1
      cursor.column = 5
      assert.equal 2, cursor.pos

    it 'adjusts the selection if it is persistent', ->
      buffer.text = 'Liñe 1 ʘf tƏxt'
      cursor.pos = 1
      selection.persistent = true
      cursor.column = 5
      assert.equals 'Liñe', selection.text

  describe '.column_index', ->
    it 'returns the real column index for the current line disregarding tabs', ->
        buffer.config.tab_width = 4
        buffer.text = '\tsome text'
        cursor.pos = 2
        assert.equal 2, cursor.column_index

    it 'returns the column index as a character offset', ->
        buffer.text = 'åäö\nåäö'
        cursor.pos = 6
        assert.equal 2, cursor.column_index

  describe '.column_index = <nr>', ->
    before_each ->
      buffer.config.tab_width = 4
      buffer.text = '\tsome text after'

    it 'moves the cursor to the specified column index', ->
      cursor.column_index = 2
      assert.equal 2, cursor.column_index
      -- assert.equal 5, cursor.column

    it 'treats <nr> as a character offset', ->
      buffer.text = 'åäö\nåäö'
      cursor.line = 2
      cursor.column_index = 2
      assert.equal 2, cursor.column_index
      -- assert.equal 6, cursor.pos

    it 'adjusts the selection if it is persistent', ->
      buffer.text = 'åäö'
      cursor.pos = 1
      selection.persistent = true
      cursor.column_index = 3
      assert.equals 'åä', selection.text

  it '.at_end_of_line returns true if cursor is at the end of the line', ->
    buffer.text = 'åäö'
    cursor.pos = 1
    assert.is_false cursor.at_end_of_line
    cursor.column = 4
    assert.is_true cursor.at_end_of_line

  it '.at_start_of_line returns true if cursor is at the start of the line', ->
    buffer.text = 'åäö'
    cursor.pos = 1
    assert.is_true cursor.at_start_of_line
    cursor.column = 2
    assert.is_false cursor.at_start_of_line

  it '.at_end_of_file returns true if cursor is at the end of the buffer', ->
    buffer.text = 'åäö'
    cursor.pos = 1
    assert.is_false cursor.at_end_of_file
    cursor\eof!
    assert.is_true cursor.at_end_of_file

  describe 'move_to(opts = {})', ->
    it 'moves the cursor to the specified line and column if given', ->
      buffer.text = 'hello\nworld'
      cursor\move_to line: 1, column: 3
      assert.equal 3, cursor.pos
      cursor\move_to line: 2, column: 2
      assert.equal 8, cursor.pos

    it 'moves the cursor to the specified pos if given', ->
      buffer.text = 'åäö'
      cursor\move_to pos: 2
      assert.equal 2, cursor.pos

    it 'extends the selection if the <extend> option is truthy', ->
      buffer.text = 'hello\nworld'
      cursor.pos = 1
      cursor\move_to line: 1, column: 3, extend: true
      assert.equal 3, cursor.pos
      assert.equal 'he', selection.text
      cursor\move_to pos: 8, extend: true
      assert.equal 8, cursor.pos
      assert.equal 'hello\nw', selection.text

    it 'considers <column> to be a virtual column', ->
      buffer.config.tab_width = 2
      buffer.text = '\t23'
      cursor\move_to line: 1, column: 3
      assert.equal 2, cursor.pos

    it 'accepts <column_index> as well, considering that a real column', ->
      buffer.config.tab_width = 2
      buffer.text = '\t23'
      cursor\move_to line: 1, column_index: 3
      assert.equal 3, cursor.pos

  it 'down() moves the cursor one line down, respecting the current column', ->
    buffer.text = 'hello\nmy\nworld'
    cursor.pos = 4

    cursor\down!
    assert.equal 2, cursor.line
    assert.equal 3, cursor.column

    cursor\down!
    assert.equal 3, cursor.line
    assert.equal 4, cursor.column

  it 'up() moves the cursor one line up, respecting the current column', ->
    cursor.line = 2
    cursor.column = 3
    cursor\up!
    assert.equal 1, cursor.line
    assert.equal 3, cursor.column

  it 'right() moves the cursor one char right', ->
    buffer.text = 'åäö'
    cursor.pos = 1
    cursor\right!
    assert.equal cursor.pos, 2

  it 'left() moves the cursor one char left', ->
    buffer.text = 'åäö'
    cursor.pos = 3
    cursor\left!
    assert.equal cursor.pos, 2

  describe 'word_right', ->
    it 'moves the cursor to the start of the following word', ->
      buffer.text = '12 xy 78'
      cursor.pos = 1
      cursor\word_right!
      assert.equal 4, cursor.pos
      cursor\word_right!
      assert.equal 7, cursor.pos

    it 'handles punctuation', ->
      buffer.text = 'foo.bar'
      cursor.pos = 1
      cursor\word_right!
      assert.equal 4, cursor.pos
      cursor\word_right!
      assert.equal 5, cursor.pos

    it 'handles tabs properly', ->
      buffer.config.tab_width = 2
      buffer.text = '\t\tfoo_bar\txy'
      cursor.pos = 3 -- 'f'
      cursor\word_right!
      assert.equal 11, cursor.pos

    it 'moves to the end of the line if no further word is available', ->
      buffer.text = '{\n34'
      cursor.pos = 1
      cursor\word_right!
      assert.equal 2, cursor.pos

      buffer.text = 'xy\n45'
      cursor.pos = 1
      cursor\word_right!
      assert.equal 3, cursor.pos

      buffer.text = '12\n45'
      cursor.pos = 1
      cursor\word_right!
      assert.equal 3, cursor.pos

    it 'handles unicode properly', ->
      buffer.text = 'LinƏ !!'
      cursor.pos = 1
      cursor\word_right!
      assert.equal 6, cursor.pos

      cursor\word_right!
      assert.equal 8, cursor.pos

    describe 'when at the end of the line', ->
      it 'moves to the first non-blank on the next line', ->
        buffer.text = '123\n  78'
        cursor.pos = 4
        cursor\word_right!
        assert.equal 7, cursor.pos

        buffer.text = '123\n56'
        cursor.pos = 4
        cursor\word_right!
        assert.equal 5, cursor.pos

      it 'does nothing if at the end of file', ->
        buffer.text = '123'
        cursor.pos = 4
        cursor\word_right!
        assert.equal 4, cursor.pos

      it 'leaves the cursor at end of file if no next word is present', ->
        buffer.text = '123'
        cursor.pos = 2
        cursor\word_right!
        assert.equal 4, cursor.pos

  describe 'word_right_end', ->
    it 'moves the cursor to the end of the current word', ->
      buffer.text = 'foo bar 56 !'
      cursor.pos = 1
      cursor\word_right_end!
      assert.equal 4, cursor.pos -- after 'foo'

      cursor\word_right_end!
      assert.equal 8, cursor.pos -- after 'bar'

      cursor\word_right_end!
      assert.equal 11, cursor.pos -- after '56'

    it 'handles punctuation', ->
      buffer.text = 'foo.bar'
      cursor.pos = 1
      cursor\word_right_end!
      assert.equal 4, cursor.pos -- '.'

      cursor\word_right_end!
      assert.equal 8, cursor.pos

    it 'handles unicode properly', ->
      buffer.text = 'LinƏ !!'
      cursor.pos = 1
      cursor\word_right_end!
      assert.equal 5, cursor.pos

      cursor\word_right_end!
      assert.equal 8, cursor.pos

      cursor.pos = 4
      cursor\word_right_end!
      assert.equal 5, cursor.pos

    it 'handles single stand-alone punctuation', ->
      buffer.text = ' { foo'
      cursor.pos = 1
      cursor\word_right_end!
      assert.equal 3, cursor.pos

    it 'handles tabs properly', ->
      buffer.config.tab_width = 2
      buffer.text = '\t\tfoo_bar\txy'
      cursor.pos = 3 -- 'f'
      cursor\word_right_end!
      assert.equal 10, cursor.pos

    describe 'when at the end of the line', ->
      it 'moves to the first non-blank on the next line', ->
        buffer.text = '123\n  78'
        cursor.pos = 4
        cursor\word_right_end!
        assert.equal 9, cursor.pos

        buffer.text = '123\n56'
        cursor.pos = 4
        cursor\word_right_end!
        assert.equal 7, cursor.pos

      it 'does nothing if at the end of file', ->
        buffer.text = '123'
        cursor.pos = 4
        cursor\word_right_end!
        assert.equal 4, cursor.pos

      it 'leaves the cursor at end of file if no next word is present', ->
        buffer.text = '12  '
        cursor.pos = 3
        cursor\word_right_end!
        assert.equal 5, cursor.pos

  describe 'word_left', ->
    it 'moves the cursor to the start of the following word', ->
      buffer.text = 'a b 12 0x !!'
      cursor.pos = 12
      cursor\word_left!
      assert.equal 11, cursor.pos -- first '!'

      cursor\word_left!
      assert.equal 8, cursor.pos -- '0'

      cursor\word_left!
      assert.equal 5, cursor.pos

      cursor\word_left!
      assert.equal 3, cursor.pos

    it 'handles punctuation', ->
      buffer.text = '(foo .bar'
      cursor.pos = 10
      cursor\word_left!
      assert.equal 7, cursor.pos
      cursor\word_left!
      assert.equal 6, cursor.pos
      cursor\word_left!
      assert.equal 2, cursor.pos
      cursor\word_left!
      assert.equal 1, cursor.pos

    it 'handles unicode properly', ->
      buffer.text = 'LinƏ åäö '
      cursor.pos = 10
      cursor\word_left!
      assert.equal 6, cursor.pos

      cursor\word_left!
      assert.equal 1, cursor.pos

    it 'handles numbers ', ->
      buffer.text = ' x 2 '
      cursor.pos = 5

      cursor\word_left!
      assert.equal 4, cursor.pos

      cursor\word_left!
      assert.equal 2, cursor.pos

    it 'handles tabs properly', ->
      buffer.config.tab_width = 2
      buffer.text = '\t\tfoo_bar\txy'
      cursor.pos = 5
      cursor\word_left!
      assert.equal 3, cursor.pos

    context 'when no further word is available', ->
      it 'moves to the end of the previous line', ->
        buffer.text = '12\n45'
        cursor.pos = 4
        cursor\word_left!
        assert.equal 3, cursor.pos

        buffer.text = '12\n 56'
        cursor.pos = 5
        cursor\word_left!
        assert.equal 3, cursor.pos

        buffer.text = 'xy\nz'
        cursor.pos = 4
        cursor\word_left!
        assert.equal 3, cursor.pos

      it 'does nothing if at the start of file', ->
        buffer.text = '123'
        cursor.pos = 1
        cursor\word_left!
        assert.equal 1, cursor.pos

      it 'moves to the start of the file if no previous line is available', ->
        buffer.text = '  34'
        cursor.pos = 3
        cursor\word_left!
        assert.equal 1, cursor.pos

  describe 'word_left_end', ->
    it 'moves the cursor to the end of the previous word', ->
      buffer.text = 'foo bar 56 !'
      cursor.pos = 13
      cursor\word_left_end!
      assert.equal 11, cursor.pos -- end of '56'

      cursor\word_left_end!
      assert.equal 8, cursor.pos -- end of 'bar'

      cursor\word_left_end!
      assert.equal 4, cursor.pos -- end of 'foo'

    it 'handles punctuation', ->
      buffer.text = 'foo.bar'
      cursor.pos = 8
      cursor\word_left_end!
      assert.equal 5, cursor.pos -- after '.'

      cursor\word_left_end!
      assert.equal 4, cursor.pos -- after 'foo'

    it 'handles single stand-alone punctuation', ->
      buffer.text = ' { foo'
      cursor.pos = 7
      cursor\word_left_end!
      assert.equal 3, cursor.pos

    it 'handles unicode properly', ->
      buffer.text = 'LiñƏ åäö x'
      cursor.pos = 10
      cursor\word_left_end!
      assert.equal 9, cursor.pos

      cursor\word_left_end!
      assert.equal 5, cursor.pos

      cursor\word_left_end!
      assert.equal 1, cursor.pos

    it 'handles tabs properly', ->
      buffer.config.tab_width = 2
      buffer.text = 'foo\tbar'
      cursor.pos = 5
      cursor\word_left_end!
      assert.equal 4, cursor.pos

    context 'when no further word is available', ->
      it 'moves to the end of the previous line', ->
        buffer.text = '12\n45'
        cursor.pos = 4
        cursor\word_left_end!
        assert.equal 3, cursor.pos

        buffer.text = '12\n 56'
        cursor.pos = 5
        cursor\word_left_end!
        assert.equal 3, cursor.pos

        buffer.text = 'xy\nz'
        cursor.pos = 4
        cursor\word_left_end!
        assert.equal 3, cursor.pos

      it 'does nothing if at the start of file', ->
        buffer.text = '123'
        cursor.pos = 1
        cursor\word_left_end!
        assert.equal 1, cursor.pos

      it 'moves to the start of the file if no previous line is available', ->
        buffer.text = '  34'
        cursor.pos = 3
        cursor\word_left_end!
        assert.equal 1, cursor.pos

  describe 'para_up', ->
    context 'when between paragraphs', ->
      it 'moves to the first previous blank line before the above paragraph', ->
        buffer.text = '12\n\n5\n7\n'
        cursor.pos = 9
        cursor\para_up!
        assert.equal 2, cursor.line

      it 'moves to the start of the buffer if no previous paragraph exists', ->
        buffer.text = '12\n\n'
        cursor.pos = 5
        cursor\para_up!
        assert.equal 1, cursor.pos

    context 'when in the middle of a paragraph', ->
      it 'moves to the first previous blank line', ->
        buffer.text = '12\n\n56\n89'
        cursor.pos = 9
        cursor\para_up!
        assert.equal 2, cursor.line

      it 'moves to the start of the buffer if no previous paragraph exists', ->
        buffer.text = '12\n45'
        cursor.pos = 5
        cursor\para_up!
        assert.equal 1, cursor.pos

  describe 'para_down', ->
    context 'when between paragraphs', ->
      it 'moves to the next blank line after the above paragraph', ->
        buffer.text = '12\n\n5\n7\n'
        cursor.pos = 4
        cursor\para_down!
        assert.equal 5, cursor.line

      it 'moves to the end of the buffer if no subsequent paragraph exists', ->
        buffer.text = '12\n\n5'
        cursor.pos = 4
        cursor\para_down!
        assert.equal 6, cursor.pos

    context 'when in the middle of a paragraph', ->
      it 'moves to the next blank line', ->
        buffer.text = '12\n45\n\n89'
        cursor.pos = 1
        cursor\para_down!
        assert.equal 3, cursor.line

      it 'moves to the end of the buffer if no subsequent paragraph exists', ->
        buffer.text = '12\n45'
        cursor.pos = 1
        cursor\para_down!
        assert.equal 6, cursor.pos

  describe 'home_indent', ->
    it 'moves the cursor to the first non-blank column', ->
      buffer.text = '  345'
      cursor.pos = 5
      cursor\home_indent!
      assert.equal 3, cursor.pos

    it 'does nothing for an empty line', ->
      buffer.text = '\nsecond'
      cursor.pos = 1
      cursor\home_indent!
      assert.equal 1, cursor.pos

    it 'handles tabs correctly', ->
      buffer.text = '\t 345'
      cursor.pos = 5
      cursor\home_indent!
      assert.equal 3, cursor.pos

  describe 'home_indent_auto', ->
    it 'toggles the cursor between the first and the first non-blank column', ->
      buffer.text = '  345'
      cursor.pos = 5

      cursor\home_indent_auto!
      assert.equal 3, cursor.pos

      cursor\home_indent_auto!
      assert.equal 1, cursor.pos

      cursor\home_indent_auto!
      assert.equal 3, cursor.pos

  context 'when passing true for extended_selection to movement commands', ->
    before_each ->
      buffer.text = [[
Liñe 1 ʘf tƏxt
And hƏre's line twʘ
]]

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
      assert.equals 'Liñe 1 ʘf tƏxt\nA', sel.text
