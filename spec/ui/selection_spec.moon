import Gtk from lgi
import Buffer from lunar
import Editor, theme from lunar.ui

text = 'Line 1 of text'

describe 'Selection', ->

  buffer = Buffer {}
  editor = Editor buffer
  selection = editor.selection
  cursor = editor.cursor
  window = Gtk.OffscreenWindow!
  window\add editor\to_gobject!
  window\show_all!

  before ->
    buffer.text = text
    selection.sci\set_empty_selection 0

  it '.anchor returns nil if nothing is selected', ->
    assert_nil selection.anchor

  it '.anchor = <pos> sets the selection to the text range [pos..<cursor>)', ->
    cursor.pos = 3
    selection.anchor = 1
    assert_equal selection.anchor, 1
    assert_equal selection.text, 'Li'

  it '.empty returns whether any selection exists', ->
    assert_true selection.empty
    selection\set 1, 3
    assert_false selection.empty

  it 'set(anchor, pos) sets the anchor and cursor at the same time', ->
    selection\set 1, 5
    assert_equal selection.text, 'Line'

  describe 'remove', ->
    it 'removes the selection', ->
      selection\set 2, 5
      selection\remove!
      assert_true selection.empty

    it 'does not remove the selected text', ->
      selection\set 2, 5
      selection\remove!
      assert_equal buffer.text, text

    it 'does not change the cursor position', ->
      selection\set 2, 5
      selection\remove!
      assert_equal cursor.pos, 5

  describe 'cut', ->
    it 'removes the selected text', ->
      selection\set 1, 5
      selection\cut!
      assert_equal buffer.text, ' 1 of text'

    it 'removes the selection', ->
      selection\set 2, 5
      selection\cut!
      assert_true selection.empty

    it 'clears the persistent flag', ->
      selection\set 1, 5
      selection.persistent = true
      selection\cut!
      assert_false selection.persistent

  describe 'copy', ->
    it 'removes the selection', ->
      selection\set 1, 5
      selection\copy!
      assert_true selection.empty

    it 'clears the persistent flag', ->
      selection\set 1, 5
      selection.persistent = true
      selection\copy!
      assert_false selection.persistent

  describe '.text', ->
    it 'returns nil if nothing is selected', ->
      assert_nil selection.text

    it 'returns the currently selected text when the selection is not empty', ->
      selection\set 1, 3
      assert_equal selection.text, 'Li'

    describe '.text = <text>', ->
      it 'replaces the selection with <text> and removes the selection', ->
        selection\set 1, 3
        selection.text = 'Shi'
        assert_equal buffer.text, 'Shine 1 of text'
        assert_true selection.empty

      it 'raises an error if the selection is empty', ->
        assert_raises 'empty', -> selection.text = 'Yowser!'
