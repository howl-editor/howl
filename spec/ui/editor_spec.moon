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
  pump_mainloop!

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

      it 'still restores the position', ->
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
        cursor\move_to line: 1, column: 6
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

    context 'when a selection is present', ->
      it 'deletes the selection before pasting', ->
        buffer.text = 'hƏllo\nwonderful\nworld'
        clipboard.push text: 'cruel'
        selection\select lines[2].start_pos, lines[2].end_pos - 1
        editor\paste!
        assert.equal 'hƏllo\ncruel\nworld', buffer.text
        assert.equal 'cruel', clipboard.current.text

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

  describe 'delete_to_end_of_line(opts)', ->
    it 'cuts text from cursor up to end of line', ->
      buffer.text = 'hƏllo world!\nnext'
      cursor.pos = 6
      editor\delete_to_end_of_line!
      assert.equal buffer.text, 'hƏllo\nnext'
      editor\paste!
      assert.equal buffer.text, 'hƏllo world!\nnext'

    it 'handles lines without EOLs', ->
      buffer.text = 'abc'
      cursor.pos = 3
      editor\delete_to_end_of_line!
      assert.equal 'ab', buffer.text

      cursor.pos = 3
      editor\delete_to_end_of_line!
      assert.equal 'ab', buffer.text

    it 'deletes without copying if no_copy is specified', ->
      buffer.text = 'hƏllo world!'
      cursor.pos = 3
      editor\delete_to_end_of_line no_copy: true
      assert.equal buffer.text, 'hƏ'
      editor\paste!
      assert.not_equal 'hƏllo world!', buffer.text

  it 'join_lines joins the current line with the one after', ->
    buffer.text = 'hƏllo\n    world!\n'
    cursor.pos = 1
    editor\join_lines!
    assert.equal 'hƏllo world!\n', buffer.text
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

    it 'updates .last_shown for buffer switched out', ->
      time = os.time
      now = time!
      os.time = -> now
      pcall ->
        editor.buffer = Buffer {}
      os.time = time
      assert.same now, buffer.last_shown

  context 'previewing', ->
    it 'does not update last_shown for previewed buffer', ->
      new_buffer = Buffer {}
      new_buffer.last_shown = 2
      editor\preview new_buffer
      editor.buffer = Buffer {}
      assert.same 2, new_buffer.last_shown

    it 'updates .last_shown for original buffer switched out', ->
      time = os.time
      now = time!
      os.time = -> now
      pcall ->
        editor\preview Buffer {}
      os.time = time
      assert.same now, buffer.last_shown

  context 'indentation, tabs, spaces and backspace', ->

    it 'defines a "tab_width" config variable, defaulting to 4', ->
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

      context 'when in whitespace and tab_indents is true', ->
        before_each ->
          config.tab_indents = true
          config.use_tabs = false
          config.indent = 2

        it 'indents the current line if in whitespace and tab_indents is true', ->
          indent = string.rep ' ', config.indent
          buffer.text = indent .. 'hƏllo'
          cursor.pos = 2
          editor\smart_tab!
          assert.equal buffer.text, string.rep(indent, 2) .. 'hƏllo'

        it 'moves the cursor to the beginning of the text', ->
          buffer.text = '  hƏllo'
          cursor.pos = 1
          editor\smart_tab!
          assert.equal 5, cursor.pos

        it 'corrects any half-off indentation', ->
          buffer.text = '   hƏllo'
          cursor.pos = 1
          editor\smart_tab!
          assert.equal 5, cursor.pos
          assert.equal '    hƏllo', buffer.text

      context 'when a selection is active', ->
        it 'right-shifts the lines included in a selection if any', ->
          config.indent = 2
          buffer.text = 'hƏllo\nselected\nworld!'
          selection\set 2, 10
          editor\smart_tab!
          assert.equal '  hƏllo\n  selected\nworld!', buffer.text

      context 'when in whitespace and tab_indents is false', ->

        it 'just inserts the corresponding tab or spaces', ->
          config.tab_indents = false
          config.indent = 2
          buffer.text = '  hƏllo'
          cursor.pos = 1

          config.use_tabs = false
          editor\smart_tab!
          assert.equal '    hƏllo', buffer.text
          assert.equal 3, cursor.pos

          config.use_tabs = true
          editor\smart_tab!
          assert.equal '  \t  hƏllo', buffer.text
          assert.equal 4, cursor.pos

    describe 'smart_back_tab()', ->
      context 'when tab_indents is false', ->
        it 'moves the cursor back to the previous tab position', ->
          config.tab_indents = false
          config.tab_width = 4
          buffer.text = '  hƏ567890'
          cursor.pos = 10

          editor\smart_back_tab!
          assert.equal 9, cursor.pos

          editor\smart_back_tab!
          assert.equal 5, cursor.pos

          editor\smart_back_tab!
          assert.equal 1, cursor.pos

          editor\smart_back_tab!
          assert.equal 1, cursor.pos

          cursor.pos = 2
          editor\smart_back_tab!
          assert.equal 1, cursor.pos

      context 'when tab_indents is true', ->
        it 'unindents when in whitespace', ->
          config.tab_indents = true
          config.tab_width = 4
          buffer.text = '    567890'
          cursor.pos = 10

          editor\smart_back_tab!
          assert.equal 9, cursor.pos

          editor\smart_back_tab!
          assert.equal 5, cursor.pos

          editor\smart_back_tab!
          assert.equal 3, cursor.pos
          assert.equal '  567890', buffer.text

          editor\smart_back_tab!
          assert.equal 1, cursor.pos
          assert.equal '567890', buffer.text

      context 'when a selection is active', ->
        it 'left-shifts the lines included in a selection if any', ->
          config.indent = 2
          buffer.text = '  hƏllo\n  selected\nworld!'
          selection\set 4, 12
          editor\smart_back_tab!
          assert.equal 'hƏllo\nselected\nworld!', buffer.text

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
        assert.equal 1, cursor.pos

      it 'deletes back if in whitespace and backspace_unindents is false', ->
        config.indent = 2
        buffer.text = '  hƏllo'
        cursor.pos = 3
        config.backspace_unindents = false
        editor\delete_back!
        assert.equal buffer.text, ' hƏllo'

      context 'with a selection', ->
        it 'deletes the selection', ->
          buffer.text = ' 2\n 5'
          selection\set 1, 5
          cursor.pos = 5
          editor\delete_back!
          assert.equal buffer.text, '5'

    describe '.delete_forward()', ->
      it 'deletes the character at cursor', ->
        buffer.text = 'hƏllo'
        cursor.pos = 2
        editor\delete_forward!
        assert.equal 'hllo', buffer.text

      context 'when a selection is active', ->
        it 'deletes the selection', ->
          buffer.text = 'hƏllo'
          editor.selection\set 2, 5
          editor\delete_forward!
          assert.equal 'ho', buffer.text
          assert.not_equal 'Əll', clipboard.current.text

      context 'when at the end of a line', ->
        it 'deletes the line break', ->
          buffer.text = 'hƏllo\nworld'
          cursor\move_to line: 1, column: 6
          editor\delete_forward!
          assert.equal 'hƏlloworld', buffer.text

      context 'when at the end of the buffer', ->
        it 'does nothing', ->
          buffer.text = 'hƏllo'
          cursor\eof!
          editor\delete_forward!
          assert.equal 'hƏllo', buffer.text

    describe '.shift_right()', ->
      before_each ->
        config.use_tabs = false
        config.indent = 2

      context 'with a selection', ->
        it 'right-shifts the lines included in the selection', ->
          buffer.text = 'hƏllo\nselected\nworld!'
          selection\set 2, 10
          editor\shift_right!
          assert.equal '  hƏllo\n  selected\nworld!', buffer.text

        it 'adjusts and keeps the selection', ->
          buffer.text = '  xx\nyy zz'
          selection\set 3, 8 -- 'xx\nyy'
          editor\shift_right!
          assert.equal 'xx\n  yy', selection.text
          assert.same { 5, 12 }, { selection\range! }

      it 'right-shifts the current line when nothing is selected, remembering column', ->
        buffer.text = 'hƏllo\nworld!'
        cursor.pos = 3
        editor\shift_right!
        assert.equal '  hƏllo\nworld!', buffer.text
        assert.equal 5, cursor.pos

    describe '.shift_left()', ->
      context 'with a selection', ->
        it 'left-shifts the lines included in the selection', ->
          config.indent = 2
          buffer.text = '  hƏllo\n  selected\nworld!'
          selection\set 4, 12
          editor\shift_left!
          assert.equal 'hƏllo\nselected\nworld!', buffer.text

        it 'adjusts and keeps the selection', ->
          buffer.text = '    xx\n  yy zz'
          selection\set 3, 12 -- '  xx\nyy'
          editor\shift_left!
          assert.equal '  xx\nyy', selection.text
          assert.same { 1, 8 }, { selection\range! }

      it 'left-shifts the current line when nothing is selected, remembering column', ->
        config.indent = 2
        buffer.text = '    hƏllo\nworld!'
        cursor.pos = 4
        editor\shift_left!
        assert.equal '  hƏllo\nworld!', buffer.text
        assert.equal 2, cursor.pos

  describe 'cycle_case()', ->
    context 'with a selection active', ->
      it 'changes all lowercase selection to all uppercase', ->
        buffer.text = 'hello selectëd #world'
        selection\set 7, 22
        editor\cycle_case!
        assert.equals 'hello SELECTËD #WORLD', buffer.text

      it 'changes all uppercase selection to titlecase', ->
        buffer.text = 'hello SELECTËD #WORLD HELLO'
        selection\set 7, 28
        editor\cycle_case!
        -- #world is not capitalized because title case considers
        -- words to be any contiguous non space chars
        assert.equals 'hello Selectëd #world Hello', buffer.text

      it 'changes mixed case selection to all lowercase', ->
        buffer.text = 'hello SelectËD #WorLd'
        selection\set 7, 22
        editor\cycle_case!
        assert.equals 'hello selectëd #world', buffer.text

      it 'preserves selection', ->
        buffer.text = 'select'
        selection\set 3, 5
        editor\cycle_case!
        assert.equals 3, selection.anchor
        assert.equals 5, selection.cursor

    context 'with no selection active', ->
      it 'changes all lowercase word to all uppercase', ->
        buffer.text = 'hello wörld'
        cursor.pos = 7
        editor\cycle_case!
        assert.equals 'hello WÖRLD', buffer.text

      it 'changes all uppercase word to titlecase', ->
        buffer.text = 'hello WÖRLD'
        cursor.pos = 7
        editor\cycle_case!
        assert.equals 'hello Wörld', buffer.text

      it 'changes mixed case word to all lowercase', ->
        buffer.text = 'hello WörLd'
        cursor.pos = 7
        editor\cycle_case!
        assert.equals 'hello wörld', buffer.text

  describe 'duplicate_current', ->
    context 'with an active selection', ->
      it 'duplicates the selection', ->
        buffer.text = 'hello\nwörld'
        cursor.pos = 2
        selection\set 2, 5 -- 'ell'
        editor\duplicate_current!
        assert.equals 'hellello\nwörld', buffer.text

      it 'keeps the cursor and current selection', ->
        buffer.text = '123456'
        selection\set 5, 2
        editor\duplicate_current!
        assert.equals 2, cursor.pos
        assert.equals 2, selection.cursor
        assert.equals 5, selection.anchor

    context 'with no active selection', ->
      it 'duplicates the current line', ->
        buffer.text = 'hello\nwörld'
        cursor.pos = 3
        editor\duplicate_current!
        assert.equals 'hello\nhello\nwörld', buffer.text

  context 'resource management', ->
    it 'editors are collected as they should', ->
      e = Editor Buffer {}
      editors = setmetatable {e}, __mode: 'v'
      e\to_gobject!\destroy!
      e = nil
      collect_memory!
      assert.is_true editors[1] == nil

    it 'releases resources after buffer switching', ->
      b1 = Buffer {}
      b2 = Buffer {}
      e = Editor b1
      buffers = setmetatable { b1, b2 }, __mode: 'v'
      editors = setmetatable { e }, __mode: 'v'
      e.buffer = b2
      e.buffer = b1
      e\to_gobject!\destroy!
      e = nil
      b1 = nil
      b2 = nil
      collectgarbage!
      assert.is_nil editors[1]
      assert.is_nil buffers[1]
      assert.is_nil buffers[2]

    it 'memory usage is stable', ->
      pinned = Editor Buffer!

      assert_memory_stays_within '40Kb', 20, ->
        e = Editor Buffer!
        e\to_gobject!\destroy!
