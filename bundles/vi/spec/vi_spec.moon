import Gtk from lgi

import Buffer, keyhandler, bundle from howl
import Editor from howl.ui

bundle.load_by_name 'vi'
state = bundles.vi.state

text = [[
LinƏ 1
LinƏ two
And third linƏ
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

  teardown -> bundle.unload 'vi'

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

  it '<r><character> replaces the current character with <character>', ->
    press 'r', 'F'
    assert.equal 'FinƏ two', lines[2].text

  it '<c><w> deletes to the end of word and enters insert', ->
    press 'c', 'w'
    assert.equal ' two', editor.current_line.text
    assert.equal 'insert', state.mode

  it '<d><d> removes the entire current line regardless of the current column', ->
    cursor.column = 4
    press 'd', 'd'
    assert.equal 'LinƏ 1\nAnd third linƏ\n', buffer.text

    -- empty lines
    buffer.text = '\n\n'
    cursor.pos = 1
    press 'd', 'd'
    assert.equal '\n', buffer.text

  it '<d><w> deletes to the start of next word', ->
    press 'd', 'w'
    assert.equal 'two', editor.current_line.text

    buffer.text = 'a.word'
    cursor.pos = 1
    press 'd', 'w'
    assert.equal '.word', buffer.text

  it '<D> deletes to the end of line', ->
    cursor.column = 5
    press 'D'
    assert.equal 'LinƏ', editor.current_line.text

  describe 'movement with destructive modifiers', ->
    for mod, check in pairs {
      d: -> true
      c: -> assert.equal 'insert', state.mode
    }

      it "<#{mod}><$> removes the line up until line break", ->
        press mod, '$'
        assert.equal 'LinƏ 1\n\nAnd third linƏ\n', buffer.text
        check!

      it "<#{mod}><0> removes back until start of line, not including current position", ->
        cursor.column = 4
        press mod, '0'
        assert.equal 'Ə two', editor.current_line.text
        check!

      it "<#{mod}><e> removes the current word", ->
        press mod, 'e'
        assert.equal ' two', editor.current_line.text
        check!

      it "<#{mod}><b> removes the current word backwards, not including current position", ->
        cursor.column = 4
        press mod, 'b'
        assert.equal 'Ə two', editor.current_line.text
        check!

  describe 'commands with counts', ->
    it 'x deletes <count> characters', ->
      buffer.text = 'hello'
      cursor.pos = 1
      press '2', 'x'
      assert.equal 'llo', buffer.text

    it 'dw deletes <count> words', ->
      buffer.text = 'hello brave new world'
      cursor.pos = 1
      press '2', 'd', 'w'
      assert.equal 'new world', buffer.text

    it 'l moves <count> characters right', ->
      buffer.text = 'åäö'
      cursor.pos = 1
      press '2', 'l'
      assert.equal 3, cursor.pos


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

  context 'repeated commands via "."', ->
    it '. repeats the last operation', ->
      buffer.text = 'hello brave new world'
      cursor.pos = 1
      press 'd', 'w'
      press '.'
      assert.equal 'new world', buffer.text

    it 'includes the applied count', ->
      buffer.text = 'hello world'
      cursor.pos = 1
      press '2', 'x'
      press '.'
      assert.equal 'o world', buffer.text

    context 'when the command has an associated edit', ->
      it 'that is repeated and command mode is re-entered', ->
        buffer.text = '\nhello world'
        cursor.pos = 2
        press 'c', 'w'
        editor\insert 'bork'
        press 'escape'
        press 'w', '.'
        assert.equal 'command', state.mode
        assert.equal '\nbork bork', buffer.text

      it 'just entering insert is considered a command', ->
        buffer.text = 'hello world'
        cursor.pos = 7
        press 'i'
        editor\insert 'ba'
        press 'escape'
        press 'l', '.'
        assert.equal 'command', state.mode
        assert.equal 'hello babaworld', buffer.text

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
        assert.equal 'nƏ', selection.text
        press 'j'
        assert.equal 'nƏ two\nAnd ', selection.text

      it 'always includes the starting position in the selection', ->
        press 'h'
        assert.equal 'in', selection.text
        press 'w'
        assert.equal 'nƏ t', selection.text
