import Gtk from lgi
import Buffer from vilu
import Editor, theme from vilu.ui

text = [[
Line 1 of text
And here's line two
And finally a third line
]]

describe 'Selection', ->

  buffer = Buffer {}
  buffer.text = text
  view = Editor buffer
  selection = view.selection
  cursor = view.cursor

  before -> selection.sci\set_empty_selection 0

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

  it 'remove removes the selection, but not the selected text', ->
    selection\set 1, 5
    selection\remove!
    assert_true selection.empty
    assert_equal buffer.text, text

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
        assert_equal buffer.text, text\gsub('^Li', 'Shi')
        assert_true selection.empty

      it 'raises an error if the selection is empty', ->
        assert_raises 'empty', -> selection.text = 'Yowser!'
