-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'

import app, Buffer, bindings, bundle, dispatch from howl
import Editor, Window from howl.ui

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
  window = Gtk.OffscreenWindow default_width: 800, default_height: 640
  window\add editor\to_gobject!
  window\show_all!

  howl.app = window: Window!

  before_each ->
    buffer = Buffer {}
    buffer.text = text
    lines = buffer.lines
    editor.buffer = buffer
    cursor.line = 2
    app.editor = editor
    state.activate editor

  after_each ->
    state.reset!
    state.deactivate!
    app.editor = nil

  teardown -> dispatch.launch -> bundle.unload 'vi'

  press = (...) ->
    for key in *{...}
      bindings.process {key_name: key, character: key, key_code: 123}, 'editor', nil, editor

  it '<j> moves down one line', ->
    press 'j'
    assert.equal 3, cursor.line

  it '<k> moves up one line', ->
    press 'k'
    assert.equal 1, cursor.line

  it '<h> moves to the left unless at the start of line', ->
    cursor.column = 2
    press 'h'
    assert.equal 1, cursor.column
    cur_pos = cursor.pos
    press 'h'
    assert.equal cur_pos, cursor.pos

  it '<l> moves to the right unless at the end of line', ->
    press 'l'
    assert.equal 2, cursor.column
    cursor\line_end!
    cur_pos = cursor.pos
    press 'l'
    assert.equal cur_pos, cursor.pos

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

  it '<f><character> searches forward in the current line to <character>', ->
    press 'f', 'n'
    assert.equal 3, cursor.column

  it '<F><character> searches backwards in the current line to <character>', ->
    cursor.column = 4
    press 'F', 'i'
    assert.equal 2, cursor.column

  it '<c><w> deletes to the end of word and enters insert', ->
    press 'c', 'w'
    assert.equal ' two', editor.current_line.text
    assert.equal 'insert', state.mode

  it 'dd removes the entire current line regardless of the current column', ->
    buffer.text = 'LinƏ 1\nSecond\nAnd third linƏ\n'
    cursor.pos = 10
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

  it '<o> opens a new line below and enters insert', ->
    buffer.text = 'first\nsecond'
    cursor.pos = 3
    press 'o'
    assert.equal cursor.line, 2
    assert.equal 'first\n\nsecond', buffer.text
    assert.equal 'insert', state.mode

  it '<y><y> yanks the current line', ->
    buffer.text = 'first\nsecond'
    cursor.pos = 3
    press 'y', 'y'
    editor\paste!
    assert.equal 'first\nfirst\nsecond', buffer.text

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

    it 'cw at end of line changes to end of line only', ->
      buffer.text = 'line1\nline2'
      cursor.pos = 5
      press 'c', 'w'
      assert.equals 'line\nline2', buffer.text
      assert.equals 5, cursor.pos
      assert.equal 'insert', state.mode

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

    it 'dd cuts <count> lines', ->
      buffer.text = 'line1\nline2\nline3'
      cursor.pos = 3
      press '2', 'd', 'd'
      assert.equals 'line3', buffer.text
      cursor.pos = 3
      editor\paste!
      assert.equals 'line1\nline2\nline3', buffer.text

    it 'Y yanks <count> lines', ->
      buffer.text = 'line1\nline2\nline3'
      cursor.pos = 3
      press '2', 'Y'
      editor\paste!
      assert.equals 'line1\nline2\nline1\nline2\nline3', buffer.text

    it 'yy yanks <count> lines', ->
      buffer.text = 'line1\nline2\nline3'
      cursor.pos = 3
      press '2', 'y', 'y'
      editor\paste!
      assert.equals 'line1\nline2\nline1\nline2\nline3', buffer.text

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
        editor\insert 'börk'
        press 'escape'
        press 'w', '.'
        assert.equal 'command', state.mode
        assert.equal '\nbörk börk', buffer.text

      it 'just entering insert is considered a command', ->
        buffer.text = 'hello world'
        cursor.pos = 7
        press 'i'
        editor\insert 'bã'
        press 'escape'
        press 'l', '.'
        assert.equal 'command', state.mode
        assert.equal 'hello bãbãworld', buffer.text

  context 'visual mode', ->
    before_each ->
      buffer.text = [[
LinƏ 1
Next LinƏ
]]
      cursor.line = 1
      cursor.column = 3
      press 'v'
      assert.equal 'visual', state.mode

    after_each -> press 'escape'

    it 'escape leaves visual mode and enters command mode', ->
      press 'escape'
      assert.equal 'command', state.mode

    it 'sets an persistent selection', ->
      assert.is_true selection.persistent

    it '">" causes the lines in the selection to be right-shifted and leaves visual', ->
      press '>'
      assert.equals '  LinƏ 1\nNext LinƏ\n', buffer.text
      assert.equal 'command', state.mode
      press 'v', 'j', '>'
      assert.equals '    LinƏ 1\n  Next LinƏ\n', buffer.text

    it '"<" causes the selection to be dedented and leaves visual', ->
      lines[i].indentation = 4 for i in *{1, 2}
      press '<'
      assert.equals '  LinƏ 1\n    Next LinƏ\n', buffer.text
      assert.equal 'command', state.mode
      press 'v', 'j', '<'
      assert.equals 'LinƏ 1\n  Next LinƏ\n', buffer.text

    context 'movement', ->
      it 'ordinary movement extends the selection', ->
        press 'l'
        assert.is_true selection.persistent
        assert.is_false selection.empty
        assert.equal 'nƏ', selection.text
        press 'j'
        assert.equal 'nƏ 1\nNext', selection.text

      it 'always includes the starting position in the selection', ->
        press 'h'
        assert.equal 'in', selection.text
        press 'w'
        assert.equal 'nƏ 1', selection.text

  describe 'unloading', ->
    before_each ->
      dispatch.launch -> bundle.unload 'vi'

    after_each ->
      dispatch.launch -> bundle.load_by_name 'vi'

    it 'pops any active keymaps, leaving only the default one', ->
      assert.equals 1, #bindings.keymaps

    it 'unregisters the vi indicator', ->
      assert.raises 'indicator', -> editor.indicator.vi
