Gtk = require 'ljglibs.gtk'
append = table.insert

{:Buffer, :config, :signal, :clipboard} = howl
{:Editor} = howl.ui

describe 'Editor', ->
  local buffer, lines
  editor = Editor Buffer {}
  cursor = editor.cursor
  selection = editor.selection
  window = Gtk.OffscreenWindow!
  window\add editor\to_gobject!
  window\show_all!

  before_each ->
    buffer = Buffer {}
    buffer.config.indent = 2
    lines = buffer.lines
    editor.buffer = buffer
    selection\remove!

  it '.current_line is a shortcut for the current buffer line', ->
    buffer.text = 'hƏllo\nworld'
    cursor.pos = 2
    assert.equal editor.current_line, buffer.lines[1]

  describe '.active_lines', ->
    context 'with no selection active', ->
      it 'is a table containing .current_line', ->
        buffer.text = 'hƏllo\nworld'
        lines = editor.active_lines
        assert.equals 1, #lines
        assert.equals editor.current_line, lines[1]

    context 'with a selection active', ->
      it 'is a table of lines involved in the selection', ->
        buffer.text = 'hƏllo\nworld'
        selection\set 3, 8
        active_lines = editor.active_lines
        assert.equals 2, #active_lines
        assert.equals lines[1], active_lines[1]
        assert.equals lines[2], active_lines[2]

  describe '.active_chunk', ->
    it 'is a chunk', ->
      assert.equals 'Chunk', typeof editor.active_chunk

    context 'with no selection active', ->
      it 'is a chunk encompassing the entire buffer text', ->
        buffer.text = 'hƏllo\nworld'
        assert.equals 'hƏllo\nworld', editor.active_chunk.text

    context 'with a selection active', ->
      it 'is a chunk containing the current the selection', ->
        buffer.text = 'hƏllo\nworld'
        selection\set 3, 8
        assert.equals 'llo\nw', editor.active_chunk.text

  it '.current_context returns the buffer context at the current position', ->
    buffer.text = 'hƏllo\nwʘrld'
    cursor.pos = 2
    context = editor.current_context
    assert.equal 'Context', typeof context
    assert.equal 2, context.pos

  it '.newline() adds a newline at the current position', ->
    buffer.text = 'hƏllo'
    cursor.pos = 3
    editor\newline!
    assert.equal buffer.text, 'hƏ\nllo'

  for method in *{ 'indent', 'comment', 'uncomment', 'toggle_comment' }
    describe "#{method}()", ->
      context "when mode does not provide a #{method} method", ->
        it 'does nothing', ->
          text = buffer.text
          editor[method] editor
          assert.equal text, buffer.text

      context "when mode provides a #{method} method", ->
        it 'calls that passing itself a parameter', ->
          buffer.mode = [method]: spy.new -> nil
          editor[method] editor
          assert.spy(buffer.mode[method]).was_called_with buffer.mode, editor

  describe 'with_position_restored(f)', ->
    before_each ->
      buffer.text = '  yowser!\n  yikes!'
      cursor.line = 2
      cursor.column = 4

    it 'calls <f> passing itself a parameter', ->
      f = spy.new -> nil
      editor\with_position_restored f
      assert.spy(f).was_called_with editor

    it 'restores the cursor position afterwards', ->
      editor\with_position_restored -> cursor.pos = 2
      assert.equals 2, cursor.line
      assert.equals 4, cursor.column

    it 'adjusts the position should the indentation have changed', ->
      editor\with_position_restored ->
        lines[1].indentation = 0
        lines[2].indentation = 0

      assert.equals 2, cursor.line
      assert.equals 2, cursor.column

      editor\with_position_restored ->
        lines[1].indentation = 3
        lines[2].indentation = 3

      assert.equals 2, cursor.line
      assert.equals 5, cursor.column

    context 'when <f> raises an error', ->
      it 'propagates the error', ->
        assert.raises 'ARGH!', -> editor\with_position_restored -> error 'ARGH!'

      it 'the position is still restored', ->
        cursor.pos = 4

        pcall editor.with_position_restored, editor, ->
          cursor.pos = 2
          error 'ARGH!'

        assert.equals 4, cursor.pos

  it 'insert(text) inserts the text at the cursor, and moves cursor after text', ->
    buffer.text = 'hƏllo'
    cursor.pos = 6
    editor\insert ' world'
    assert.equal 'hƏllo world', buffer.text
    assert.equal 12, cursor.pos, 12

  describe 'paste(opts = {})', ->
    it 'pastes the current clip of the clipboard at the current position', ->
      buffer.text = 'hƏllo'
      clipboard.push ' wörld'
      cursor\eof!
      editor\paste!
      assert.equal 'hƏllo wörld', buffer.text

    context 'when opts.clip is specified', ->
      it 'pastes that clip at the current position', ->
        clipboard.push 'hello'
        clip = clipboard.current
        clipboard.push 'wörld'
        buffer.text = 'well '
        cursor\eof!
        editor\paste :clip
        assert.equal 'well hello', buffer.text

    context 'when opts.where is set to "after"', ->
      it 'pastes the clip to the right of the current position', ->
        buffer.text = 'hƏllo\n'
        clipboard.push 'yo'
        cursor\move_to 1, 6
        editor\paste where: 'after'
        assert.equal 'hƏllo yo\n', buffer.text
        cursor\eof!
        editor\paste where: 'after'
        assert.equal 'hƏllo yo\n yo', buffer.text

    context 'when the clip item has .whole_lines set', ->
      it 'pastes the clip on a newly opened line above the current', ->
        buffer.text = 'hƏllo\nworld'
        clipboard.push text: 'cruel', whole_lines: true
        cursor.line = 2
        cursor.column = 3
        editor\paste!
        assert.equal 'hƏllo\ncruel\nworld', buffer.text

      it 'pastes the clip at the start of a line if ends with a newline separator', ->
        buffer.text = 'hƏllo\nworld'
        clipboard.push text: 'cruel\n', whole_lines: true
        cursor.line = 2
        cursor.column = 3
        editor\paste!
        assert.equal 'hƏllo\ncruel\nworld', buffer.text

      it 'positions the cursor at the start of the pasted clip', ->
        buffer.text = 'paste'
        clipboard.push text: 'much', whole_lines: true
        cursor.column = 3
        editor\paste!
        assert.equal 1, cursor.pos

      context 'when opts.where is set to "after"', ->
        it 'pastes the clip on a newly opened line below the current', ->
          buffer.text = 'hƏllo\nworld'
          clipboard.push text: 'cruel', whole_lines: true
          cursor.line = 1
          cursor.column = 3
          editor\paste where: 'after'
          assert.equal 'hƏllo\ncruel\nworld', buffer.text

  it 'delete_line() deletes the current line', ->
    buffer.text = 'hƏllo\nworld!'
    cursor.pos = 3
    editor\delete_line!
    assert.equal 'world!', buffer.text

  it 'copy_line() copies the current line', ->
    buffer.text = 'hƏllo\n'
    cursor.pos = 3
    editor\copy_line!
    cursor.pos = 1
    editor\paste!
    assert.equal 'hƏllo\nhƏllo\n', buffer.text

  describe 'delete_to_end_of_line(no_copy)', ->
    it 'cuts text from cursor up to end of line', ->
      buffer.text = 'hƏllo world!\nnext'
      cursor.pos = 6
      editor\delete_to_end_of_line!
      assert.equal buffer.text, 'hƏllo\nnext'
      editor\paste!
      assert.equal buffer.text, 'hƏllo world!\nnext'

    it 'deletes without copying if no_copy is specified', ->
      buffer.text = 'hƏllo world!'
      cursor.pos = 3
      editor\delete_to_end_of_line true
      assert.equal buffer.text, 'hƏ'
      editor\paste!
      assert.not_equal 'hƏllo world!', buffer.text

  it 'join_lines joins the current line with the one after', ->
    buffer.text = 'hƏllo\n    world!'
    cursor.pos = 1
    editor\join_lines!
    assert.equal 'hƏllo world!', buffer.text
    assert.equal 6, cursor.pos

  it 'forward_to_match(string) moves the cursor to next occurence of <string>, if found in the line', ->
    buffer.text = 'hƏll\to\n    world!'
    cursor.pos = 1
    editor\forward_to_match 'l'
    assert.equal 3, cursor.pos
    editor\forward_to_match 'l'
    assert.equal 4, cursor.pos
    editor\forward_to_match 'o'
    assert.equal 6, cursor.pos
    editor\forward_to_match 'w'
    assert.equal 6, cursor.pos

  it 'backward_to_match(string) moves the cursor back to previous occurence of <string>, if found in the line', ->
    buffer.text = 'h\tƏllo\n    world!'
    cursor.pos = 6
    editor\backward_to_match 'l'
    assert.equal 5, cursor.pos
    editor\backward_to_match 'l'
    assert.equal 4, cursor.pos
    editor\backward_to_match 'h'
    assert.equal 1, cursor.pos
    editor\backward_to_match 'w'
    assert.equal 1, cursor.pos

  context 'buffer switching', ->
    it 'remembers the position for different buffers', ->
      buffer.text = 'hƏllo\n    world!'
      cursor.pos = 8
      buffer2 = Buffer {}
      buffer2.text = 'a whole different whale'
      editor.buffer = buffer2
      cursor.pos = 15
      editor.buffer = buffer
      assert.equal 8, cursor.pos
      editor.buffer = buffer2
      assert.equal 15, cursor.pos

  context 'indentation, tabs, spaces and backspace', ->

    it 'defines a "tab_width" config variable, defaulting to 8', ->
      assert.equal config.tab_width, 4

    it 'defines a "use_tabs" config variable, defaulting to false', ->
      assert.equal config.use_tabs, false

    it 'defines a "indent" config variable, defaulting to 2', ->
      assert.equal config.indent, 2

    it 'defines a "tab_indents" config variable, defaulting to true', ->
      assert.equal config.tab_indents, true

    it 'defines a "backspace_unindents" config variable, defaulting to true', ->
      assert.equal config.backspace_unindents, true

    describe 'smart_tab()', ->
      it 'inserts a tab character if use_tabs is true', ->
        config.use_tabs = true
        buffer.text = 'hƏllo'
        cursor.pos = 2
        editor\smart_tab!
        assert.equal buffer.text, 'h\tƏllo'

      it 'inserts spaces to move to the next tab if use_tabs is false', ->
        config.use_tabs = false
        buffer.text = 'hƏllo'
        cursor.pos = 1
        editor\smart_tab!
        assert.equal string.rep(' ', config.indent) .. 'hƏllo', buffer.text

      it 'inserts a tab to move to the next tab stop if use_tabs is true', ->
        config.use_tabs = true
        config.tab_width = config.indent
        buffer.text = 'hƏllo'
        cursor.pos = 1
        editor\smart_tab!
        assert.equal '\thƏllo', buffer.text

      it 'indents the current line if in whitespace and tab_indents is true', ->
        config.use_tabs = false
        config.tab_indents = true
        indent = string.rep ' ', config.indent
        buffer.text = indent .. 'hƏllo'
        cursor.pos = 2
        editor\smart_tab!
        assert.equal buffer.text, string.rep(indent, 2) .. 'hƏllo'

    describe '.delete_back()', ->
      it 'deletes back by one character', ->
        buffer.text = 'hƏllo'
        cursor.pos = 2
        editor\delete_back!
        assert.equal buffer.text, 'Əllo'

      it 'unindents if in whitespace and backspace_unindents is true', ->
        config.indent = 2
        buffer.text = '  hƏllo'
        cursor.pos = 3
        config.backspace_unindents = true
        editor\delete_back!
        assert.equal buffer.text, 'hƏllo'

      it 'deletes back if in whitespace and backspace_unindents is false', ->
        config.indent = 2
        buffer.text = '  hƏllo'
        cursor.pos = 3
        config.backspace_unindents = false
        editor\delete_back!
        assert.equal buffer.text, ' hƏllo'

    describe '.shift_right()', ->
      it 'right-shifts the lines included in a selection if any', ->
        config.indent = 2
        buffer.text = 'hƏllo\nselected\nworld!'
        selection\set 2, 10
        editor\shift_right!
        assert.equal buffer.text, '  hƏllo\n  selected\nworld!'

      it 'right-shifts the current line when nothing is selected, remembering column', ->
        config.indent = 2
        buffer.text = 'hƏllo\nworld!'
        cursor.pos = 3
        editor\shift_right!
        assert.equal buffer.text, '  hƏllo\nworld!'
        assert.equal cursor.pos, 5

    describe '.shift_left()', ->
      it 'left-shifts the lines included in a selection if any', ->
        config.indent = 2
        buffer.text = '  hƏllo\n  selected\nworld!'
        selection\set 4, 12
        editor\shift_left!
        assert.equal buffer.text, 'hƏllo\nselected\nworld!'

      it 'left-shifts the current line when nothing is selected, remembering column', ->
        config.indent = 2
        buffer.text = '    hƏllo\nworld!'
        cursor.pos = 4
        editor\shift_left!
        assert.equal buffer.text, '  hƏllo\nworld!'
        assert.equal cursor.pos, 2

  context 'events', ->
    describe 'on char added', ->
      it 'emits a character-added event with the passed arguments merged with the editor reference', ->
        handler = spy.new -> true
        signal.connect 'character-added', handler
        args = key_name: 'a'
        editor\_on_char_added args
        signal.disconnect 'character-added', handler
        args.editor = editor
        assert.spy(handler).was_called_with args

      it 'invokes mode.on_char_added if present, passing (arguments, editor)', ->
        buffer.mode = on_char_added: spy.new -> nil
        args = key_name: 'a', :editor
        editor\_on_char_added args
        assert.spy(buffer.mode.on_char_added).was_called_with buffer.mode, args, editor

  context 'resource management', ->
    it 'editors are collected as they should', ->
      e = Editor Buffer {}
      editors = setmetatable {}, __mode: 'v'
      append editors, e
      e = nil
      collectgarbage!
      assert.is_nil editors[1]
