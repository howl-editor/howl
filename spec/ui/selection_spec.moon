import Gtk from lgi
import Buffer from lunar
import Editor, theme from lunar.ui

text = 'Line 1 of text\nLine 2 of text'

describe 'Selection', ->

  buffer = Buffer {}
  editor = Editor buffer
  selection = editor.selection
  cursor = editor.cursor
  window = Gtk.OffscreenWindow!
  window\add editor\to_gobject!
  window\show_all!

  before_each ->
    buffer.text = text
    selection.sci\set_empty_selection 0

  it 'set(anchor, pos) sets the anchor and cursor at the same time', ->
    selection\set 1, 5
    assert.equal 'Line', selection.text

  describe '.anchor', ->
    it 'returns the current position if nothing is selected', ->
      cursor.pos = 3
      assert.equal 3, selection.anchor

    it 'returns the start position of the selection with a selection active', ->
      selection\set 2, 5
      assert.equal 2, selection.anchor

    it 'setting it to <pos> sets the selection to the text range [pos..<cursor>)', ->
      cursor.pos = 3
      selection.anchor = 1
      assert.equal 1, selection.anchor
      assert.equal 'Li', selection.text

  describe '.cursor', ->
    it 'returns the current position if nothing is selected', ->
      cursor.pos = 3
      assert.equal 3, selection.cursor

    it 'returns the end position of the selection with a selection active', ->
      selection\set 2, 5
      assert.equal 5, selection.cursor

      selection.anchor = 3
      selection.cursor = 5
      assert.equal 5, selection.cursor
      assert.equal 'ne', selection.text

  it '.empty returns whether any selection exists', ->
    assert.is_true selection.empty
    selection\set 1, 3
    assert.is_false selection.empty

  describe '.persistent', ->
    it 'causes the selection to be extended with movement when true', ->
      cursor.pos = 1
      selection.persistent = true
      cursor\down!
      assert.equal 'Line 1 of text\n', selection.text

  it 'range() returns the [start, stop) range of the selection in ascending order', ->
    selection\set 2, 5
    start, stop = selection\range!
    assert.equal 2, start
    assert.equal 5, stop

    selection\set 5, 2
    start, stop = selection\range!
    assert.equal 2, start
    assert.equal 5, stop

  describe 'remove', ->
    it 'removes the selection', ->
      selection\set 2, 5
      selection\remove!
      assert.is_true selection.empty

    it 'does not remove the selected text', ->
      selection\set 2, 5
      selection\remove!
      assert.equal text, buffer.text

    it 'does not change the cursor position', ->
      selection\set 2, 5
      selection\remove!
      assert.equal 5, cursor.pos

  describe 'cut', ->
    it 'removes the selected text', ->
      selection\set 1, 5
      selection\cut!
      assert.equal ' 1 of text', buffer.lines[1].text

    it 'removes the selection', ->
      selection\set 2, 5
      selection\cut!
      assert.is_true selection.empty

    it 'clears the persistent flag', ->
      selection\set 1, 5
      selection.persistent = true
      selection\cut!
      assert.is_false selection.persistent

    it 'places the contents on the clipboard, ready for pasting', ->
      selection\set 1, 5
      selection\cut!
      editor\paste!
      assert.equal 'Line 1 of text', buffer.lines[1].text

  describe 'copy', ->
    it 'removes the selection', ->
      selection\set 1, 5
      selection\copy!
      assert.is_true selection.empty

    it 'clears the persistent flag', ->
      selection\set 1, 5
      selection.persistent = true
      selection\copy!
      assert.is_false selection.persistent

    it 'places the contents on the clipboard, ready for pasting', ->
      selection\set 1, 5
      selection\copy!
      editor\paste!
      assert.equal 'LineLine 1 of text', buffer.lines[1].text

  describe '.text', ->
    it 'returns nil if nothing is selected', ->
      assert.is_nil selection.text

    it 'returns the currently selected text when the selection is not empty', ->
      selection\set 1, 3
      assert.equal 'Li', selection.text

    describe '.text = <text>', ->
      it 'replaces the selection with <text> and removes the selection', ->
        selection\set 1, 3
        selection.text = 'Shi'
        assert.equal 'Shine 1 of text', buffer.lines[1].text
        assert.is_true selection.empty

      it 'raises an error if the selection is empty', ->
        assert.raises 'empty', -> selection.text = 'Yowser!'

  describe 'when .includes_cursor is set to true', ->
    before_each -> selection.includes_cursor = true
    after_each -> selection.includes_cursor = false

    it '.text includes the current character', ->
      selection\set 1, 4
      selection.includes_cursor = true
      assert.equal 'Line', selection.text

    it '.text = <text> replaces the current character as well', ->
      selection\set 1, 2
      selection.text = 'Shi'
      assert.equal 'Shine 1 of text', buffer.lines[1].text

    it 'range() includes the cursor position if needed', ->
      selection\set 2, 5
      start, stop = selection\range!
      assert.equal 2, start
      assert.equal 6, stop

      selection\set 5, 2
      start, stop = selection\range!
      assert.equal 2, start
      assert.equal 5, stop

    it 'cut() removes the current character as well', ->
      selection\set 1, 5
      selection\cut!
      assert.equal '1 of text', buffer.lines[1].text

    it 'copy() copies the current character as well', ->
      selection\set 1, 4
      selection\copy!
      cursor.column = 1
      editor\paste!
      assert.equal 'LineLine 1 of text', buffer.lines[1].text

    it '.empty is only false at eof', ->
      assert.is_false selection.empty
      cursor\eof!
      assert.is_true selection.empty
      cursor\left!
      assert.is_false selection.empty
