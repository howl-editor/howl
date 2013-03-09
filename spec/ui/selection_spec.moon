import Gtk from lgi
import Buffer, signal from howl
import Editor, theme from howl.ui

text = 'Liñe 1 ʘf tƏxt\nLiñe 1 ʘf tƏxt'

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
    assert.equal 'Liñe', selection.text

  it 'select(anchor, pos) adjusts the selection to include the specifed range', ->
    selection\select 1, 4
    assert.equal 5, selection.cursor
    assert.equal 'Liñe', selection.text

    selection\select 4, 2
    assert.equal 5, selection.anchor
    assert.equal 'iñe', selection.text

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
      assert.equal 'ñe', selection.text

  it '.empty returns whether any selection exists', ->
    assert.is_true selection.empty
    selection\set 1, 3
    assert.is_false selection.empty

  describe '.persistent', ->
    it 'causes the selection to be extended with movement when true', ->
      cursor.pos = 1
      selection.persistent = true
      cursor\down!
      assert.equal 'Liñe 1 ʘf tƏxt\n', selection.text

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

    it 'signals "selection-removed"', ->
      with_signal_handler 'selection-removed', (handler) ->
        selection\set 2, 5
        selection\remove!
        assert.spy(handler).was_called!

  describe 'cut', ->
    it 'removes the selected text', ->
      selection\set 1, 5
      selection\cut!
      assert.equal ' 1 ʘf tƏxt', buffer.lines[1].text

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
      assert.equal 'Liñe 1 ʘf tƏxt', buffer.lines[1].text

    it 'signals "selection-removed"', ->
      with_signal_handler 'selection-removed', (handler) ->
        selection\set 1, 5
        selection\cut!
        assert.spy(handler).was_called!

    it 'signals "selection-cut"', ->
      with_signal_handler 'selection-cut', (handler) ->
        selection\set 1, 5
        selection\cut!
        assert.spy(handler).was_called!

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
      assert.equal 'LiñeLiñe 1 ʘf tƏxt', buffer.lines[1].text

    it 'signals "selection-removed"', ->
      with_signal_handler 'selection-removed', (handler) ->
        selection\set 1, 5
        selection\copy!
        assert.spy(handler).was_called!

    it 'signals "selection-copied"', ->
      with_signal_handler 'selection-copied', (handler) ->
        selection\set 1, 5
        selection\copy!
        assert.spy(handler).was_called!

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
        assert.equal 'Shiñe 1 ʘf tƏxt', buffer.lines[1].text
        assert.is_true selection.empty

      it 'raises an error if the selection is empty', ->
        assert.raises 'empty', -> selection.text = 'Yowser!'

  describe 'when .includes_cursor is set to true', ->
    before_each -> selection.includes_cursor = true
    after_each -> selection.includes_cursor = false

    it 'select(anchor, pos) adjusts pos if needed to only point at the end of selection', ->
      selection\select 1, 4
      assert.equal 4, selection.cursor
      assert.equal 'Liñe', selection.text

      selection\select 4, 2
      assert.equal 5, selection.anchor
      assert.equal 'iñe', selection.text

    it '.text #includes the current character', ->
      selection\set 1, 3
      selection.includes_cursor = true
      assert.equal 'Liñ', selection.text

    it '.text = <text> replaces the current character as well', ->
      selection\set 1, 2
      selection.text = 'Shi'
      assert.equal 'Shiñe 1 ʘf tƏxt', buffer.lines[1].text

    describe 'range()', ->
      it 'includes the cursor position if needed', ->
        selection\set 2, 5
        start, stop = selection\range!
        assert.equal 2, start
        assert.equal 6, stop

        selection\set 5, 2
        start, stop = selection\range!
        assert.equal 2, start
        assert.equal 5, stop

      it 'does not include an position after eof however', ->
        selection\set #buffer - 1, #buffer + 1
        start, stop = selection\range!
        assert.equal #buffer - 1, start
        assert.equal #buffer + 1, stop

    it 'cut() removes the current character as well', ->
      selection\set 1, 5
      selection\cut!
      assert.equal '1 ʘf tƏxt', buffer.lines[1].text

    it 'copy() copies the current character as well', ->
      selection\set 1, 4
      selection\copy!
      cursor.column = 1
      editor\paste!
      assert.equal 'LiñeLiñe 1 ʘf tƏxt', buffer.lines[1].text

    it '.empty is only false at eof', ->
      assert.is_false selection.empty
      cursor\eof!
      assert.is_true selection.empty
      cursor\left!
      assert.is_false selection.empty
