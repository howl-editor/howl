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

  it '.anchor returns nil if nothing is selected', ->
    assert.is_nil selection.anchor

  it '.anchor = <pos> sets the selection to the text range [pos..<cursor>)', ->
    cursor.pos = 3
    selection.anchor = 1
    assert.equal selection.anchor, 1
    assert.equal selection.text, 'Li'

  it '.empty returns whether any selection exists', ->
    assert.is_true selection.empty
    selection\set 1, 3
    assert.is_false selection.empty

  it 'set(anchor, pos) sets the anchor and cursor at the same time', ->
    selection\set 1, 5
    assert.equal selection.text, 'Line'

  describe '.persistent', ->
    it 'causes the selection to be extended with movement when true', ->
      cursor.pos = 1
      selection.persistent = true
      cursor\down!
      assert.equal 'Line 1 of text\n', selection.text

  describe 'remove', ->
    it 'removes the selection', ->
      selection\set 2, 5
      selection\remove!
      assert.is_true selection.empty

    it 'does not remove the selected text', ->
      selection\set 2, 5
      selection\remove!
      assert.equal buffer.text, text

    it 'does not change the cursor position', ->
      selection\set 2, 5
      selection\remove!
      assert.equal cursor.pos, 5

  describe 'cut', ->
    it 'removes the selected text', ->
      selection\set 1, 5
      selection\cut!
      assert.equal buffer.lines[1].text, ' 1 of text'

    it 'removes the selection', ->
      selection\set 2, 5
      selection\cut!
      assert.is_true selection.empty

    it 'clears the persistent flag', ->
      selection\set 1, 5
      selection.persistent = true
      selection\cut!
      assert.is_false selection.persistent

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

  describe '.text', ->
    it 'returns nil if nothing is selected', ->
      assert.is_nil selection.text

    it 'returns the currently selected text when the selection is not empty', ->
      selection\set 1, 3
      assert.equal selection.text, 'Li'

    describe '.text = <text>', ->
      it 'replaces the selection with <text> and removes the selection', ->
        selection\set 1, 3
        selection.text = 'Shi'
        assert.equal buffer.lines[1].text, 'Shine 1 of text'
        assert.is_true selection.empty

      it 'raises an error if the selection is empty', ->
        assert.raises 'empty', -> selection.text = 'Yowser!'
