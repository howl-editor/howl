import Gtk from lgi

import Buffer, keyhandler, bundle from lunar
import Editor from lunar.ui

bundle.load_by_name 'vi'
state = bundles.vi.state

text = [[
Line 1
Line two
And third line
]]

describe 'VI', ->
  local buffer, lines
  editor = Editor Buffer {}
  cursor = editor.cursor
  selection = editor.selection
  window = Gtk.OffscreenWindow!
  window\add editor\to_gobject!
  window\show_all!

  before_each ->
    buffer = Buffer {}
    buffer.text = text
    lines = buffer.lines
    editor.buffer = buffer
    cursor.line = 2
    _G.editor = editor

  after_each ->
    state.reset!
    _G.editor = nil

  press = (...) ->
    for key in *{...}
      keyhandler.process editor, key_name: key, character: key, key_code: 123

  it '<j> moves down one line', ->
    press 'j'
    assert.equal 3, cursor.line

  it '<k> moves up one line', ->
    press 'k'
    assert.equal 1, cursor.line

  it '<h> moves to the left, or up a line if at the start of line', ->
    cursor.column = 2
    press 'h'
    assert.equal 1, cursor.column
    press 'h'
    assert.equal 1, cursor.line

  it '<l> moves to the right, or down a line if at the end of line', ->
    press 'l'
    assert.equal 2, cursor.column
    cursor\line_end!
    press 'l'
    assert.equal 3, cursor.line

  it '<w> moves one word to the right', ->
    press 'w'
    assert.equal 6, cursor.column
    cursor\line_end!
    press 'w'
    assert.equal 3, cursor.line
    assert.equal 1, cursor.column

  it '<e> moves to the last character of the current word', ->
    press 'e'
    assert.equal 4, cursor.column
    press 'e'
    assert.equal 8, cursor.column

  it '<$> moves to the last character of the current line', ->
    press '$'
    assert.equal #buffer.lines[2], cursor.column

  it '<cw> deletes to the end of word and enters insert', ->
    press 'c', 'w'
    assert.equal ' two', editor.current_line.text
    assert.equal 'insert', state.mode

  it '<r><character> replaces the current character with <character>', ->
    press 'r', 'F'
    assert.equal 'Fine two', lines[2].text

  describe '<d><d>', ->
    it 'removes the entire current line regardless of the current column', ->
      cursor.column = 4
      press 'd', 'd'
      assert.equal 'Line 1\nAnd third line\n', buffer.text

  context 'insert mode', ->
    before_each -> press 'i'

    describe 'escape', ->
      it 'exits insert mode and enters command mode', ->
        press 'escape'
        assert.equal 'command', state.mode

      it 'moves the cursor one back unless at the start of the line', ->
        cursor.column = 2
        press 'escape'
        assert.equal 1, cursor.column
        press 'i'
        press 'escape'
        assert.equal 1, cursor.column

  context 'visual mode', ->
    before_each ->
      cursor.column = 3
      press 'v'
      assert.equal 'visual', state.mode

    after_each -> press 'escape'

    it 'escape leaves visual mode and enters command mode', ->
      press 'escape'
      assert.equal 'command', state.mode

    it 'sets an persistent selection', ->
      assert.is_true selection.persistent

    context 'movement', ->
      it 'ordinary movement extends the selection', ->
        press 'l'
        assert.is_false selection.empty
        assert.equal 'ne', selection.text
        press 'j'
        assert.equal 'ne two\nAnd ', selection.text

      it 'always includes the starting position in the selection', ->
        press 'h'
        assert.equal 'in', selection.text
        press 'w'
        assert.equal 'ne t', selection.text
