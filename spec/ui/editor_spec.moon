import Gtk from lgi

import Buffer, config from howl
import Editor from howl.ui

describe 'Editor', ->
  local buffer, lines
  editor = Editor Buffer {}
  cursor = editor.cursor
  selection = editor.selection
  window = Gtk.OffscreenWindow!
  window\add editor\to_gobject!
  window\show_all!

  teardown -> window\destroy!

  before_each ->
    buffer = Buffer {}
    config.set 'indent', 2, buffer
    lines = buffer.lines
    editor.buffer = buffer

  it '.current_line is a shortcut for the current buffer line', ->
    buffer.text = 'hƏllo\nworld'
    cursor.pos = 2
    assert.equal editor.current_line, buffer.lines[1]

  it '.current_word returns the word chunk at the current position', ->
    buffer.text = 'hƏllo\nwʘrld'
    cursor.pos = 2
    word = editor.current_word
    assert.equal 'hƏllo', word.text
    assert.equal 1, word.start_pos
    assert.equal 5, word.end_pos
    cursor.pos = 7
    assert.equal 'wʘrld', editor.current_word.text

  it '.newline() adds a newline at the current position', ->
    buffer.text = 'hƏllo'
    cursor.pos = 3
    editor\newline!
    assert.equal buffer.text, 'hƏ\nllo'

  describe '.indent()', ->
    context "when the buffer's mode provides an .indent_for", ->
      it 'is called with (mode, line, indent_level, editor)', ->
        indent_for = spy.new!
        buffer.mode = :indent_for
        editor\indent!
        assert.spy(indent_for).was.called_with buffer.mode, editor.current_line, 2, editor

      it 'the line indentation is set to the return value if not nil', ->
        buffer.mode = indent_for: -> 2
        buffer.text = 'line'
        editor\indent!
        assert.equal '  line', buffer.text

      it 'the cursor is moved to the beginning of indentation if would be positioned before', ->
        buffer.mode = indent_for: -> 2
        buffer.text = 'line'
        cursor.column = 1
        editor\indent!
        assert.equal '  line', buffer.text
        assert.equal 3, cursor.column

    context "when the buffer's mode does not provide an .indent_for", ->
      it 'does nothing', ->
        buffer.text = 'line'
        editor\indent!
        assert.equal 'line', buffer.text

  describe '.newline_and_format()', ->
    it 'adds a newline and sets the indentation to that of the previous line', ->
      buffer.text = '  line'
      cursor.pos = 7
      editor\newline_and_format!
      assert.equal buffer.text, '  line\n  '

    it 'does the whole shebang as a one undo', ->
      buffer.text = '  line'
      cursor.pos = 7
      editor\newline_and_format!
      editor.buffer\undo!
      assert.equal buffer.text, '  line'

    it 'positions the cursor at the end of the indentation', ->
      buffer.text = '  line'
      cursor.pos = 7
      editor\newline_and_format!
      assert.equal editor.cursor.line, 2
      assert.equal editor.cursor.column, 3

    context "when the buffer's mode provides an .indent_for", ->
     it "indents the current line and the next line according to the returned indent level", ->
        buffer.mode = indent_for: (line) => line\match('else') and 0 or 2
        buffer.text = '  line\n  else'
        cursor.line = 2
        cursor\line_end!
        editor\newline_and_format!
        assert.equal '  line\nelse\n  ', buffer.text

    context "when the buffer's mode provides an .after_newline", ->
      it 'is called with (mode, current-line, editor)', ->
        after_newline = spy.new!
        buffer.mode = :after_newline
        buffer.text = 'line'
        cursor.pos = 3
        editor\newline_and_format!
        assert.spy(after_newline).was.called_with buffer.mode, buffer.lines[2], editor

  describe 'comment()', ->
    text = [[
  liñe 1
    liñe 2
    liñe 3
]]
    before_each ->
      buffer.text = text
      selection\set 1, lines[3].start_pos

    context 'when mode does not provide .short_comment_prefix', ->
      it 'does nothing', ->
        editor\comment!
        assert.equal text, buffer.text

    context 'when mode provides .short_comment_prefix', ->
      before_each -> buffer.mode = short_comment_prefix: '--'

      it 'prefixes the selected lines with the prefix and a space, at the minimum indentation level', ->
        editor\comment!
        assert.equal [[
  -- liñe 1
  --   liñe 2
    liñe 3
]], buffer.text

      it 'comments the current line if nothing is selected', ->
        selection\remove!
        cursor.pos = 1
        editor\comment!
        assert.equal [[
  -- liñe 1
    liñe 2
    liñe 3
]], buffer.text

      it 'keeps the cursor position', ->
        editor.selection.cursor = lines[2].start_pos + 2
        editor\comment!
        assert.equal 6, cursor.column

  describe 'uncomment()', ->
    text = [[
  -- liñe 1
    -- -- liñe 2
    liñe 3
]]
    before_each ->
      buffer.text = text
      selection\set 1, lines[3].start_pos

    context 'when mode does not provide .short_comment_prefix', ->
      it 'does nothing', ->
        editor\comment!
        assert.equal text, buffer.text

    context 'when mode provides .short_comment_prefix', ->
      before_each -> buffer.mode = short_comment_prefix: '--'

      it 'removes the first instance of the comment prefix from each line', ->
        editor\uncomment!
        assert.equal [[
  liñe 1
    -- liñe 2
    liñe 3
]], buffer.text

      it 'uncomments the current line if nothing is selected', ->
        selection\remove!
        cursor.line = 2
        editor\uncomment!
        assert.equal [[
  -- liñe 1
    -- liñe 2
    liñe 3
]], buffer.text

      it 'keeps the cursor position', ->
        editor.selection.cursor = lines[2].start_pos + 6
        editor\uncomment!
        assert.equal 4, cursor.column

  describe 'toggle_comment()', ->
    context 'when mode does not provide .short_comment_prefix', ->
      it 'does nothing', ->
        buffer.text = '-- foo'
        editor\toggle_comment!
        assert.equal '-- foo', buffer.text

    context 'when mode provides .short_comment_prefix', ->
      before_each -> buffer.mode = short_comment_prefix: '--'

      it 'it uncomments if the first line starts with the comment prefix', ->
        buffer.text = '  -- foo'
        editor\toggle_comment!
        assert.equal '  foo', buffer.text

      it 'comments if the first line do no start with the comment prefix', ->
        buffer.text = 'foo'
        editor\toggle_comment!
        assert.equal '-- foo', buffer.text

  it 'insert(text) inserts the text at the cursor, and moves cursor after text', ->
    buffer.text = 'hƏllo'
    cursor.pos = 6
    editor\insert ' world'
    assert.equal buffer.text, 'hƏllo world'
    assert.equal cursor.pos, 12

  it 'paste pastes the contents of the clipboard at the current position', ->
    buffer.text = 'hƏllo'
    editor.selection\set 1, 2
    editor.selection\copy!
    editor\paste!
    assert.equal buffer.text, 'hhƏllo'

  it 'delete_line deletes the current line', ->
    buffer.text = 'hƏllo\nworld!'
    cursor.pos = 3
    editor\delete_line!
    assert.equal buffer.text, 'world!'

  it 'copy_line copies the current line', ->
    buffer.text = 'hƏllo\n'
    cursor.pos = 3
    editor\copy_line!
    cursor.pos = 1
    editor\paste!
    assert.equal buffer.text, 'hƏllo\nhƏllo\n'

  it 'delete_to_end_of_line deletes text from cursor up to end of line', ->
    buffer.text = 'hƏllo world!'
    cursor.pos = 6
    editor\delete_to_end_of_line!
    assert.equal buffer.text, 'hƏllo'

  it 'join_lines joins the current line with the one after', ->
    buffer.text = 'hƏllo\n    world!'
    cursor.pos = 1
    editor\join_lines!
    assert.equal 'hƏllo world!', buffer.text
    assert.equal 6, cursor.pos

  it 'forward_to_match(string) moves the cursor to next occurence of <string>, if found in the line', ->
    buffer.text = 'hƏllo\n    world!'
    cursor.pos = 1
    editor\forward_to_match 'l'
    assert.equal 3, cursor.pos
    editor\forward_to_match 'l'
    assert.equal 4, cursor.pos
    editor\forward_to_match 'o'
    assert.equal 5, cursor.pos
    editor\forward_to_match 'w'
    assert.equal 5, cursor.pos

  it 'backward_to_match(string) moves the cursor back to previous occurence of <string>, if found in the line', ->
    buffer.text = 'hƏllo\n    world!'
    cursor.pos = 5
    editor\backward_to_match 'l'
    assert.equal 4, cursor.pos
    editor\backward_to_match 'l'
    assert.equal 3, cursor.pos
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

    it 'defines a "tab_width" config variable, defaulting to 2', ->
      assert.equal config.tab_width, 2

    it 'defines a "use_tabs" config variable, defaulting to false', ->
      assert.equal config.use_tabs, false

    it 'defines a "indent" config variable, defaulting to 2', ->
      assert.equal config.indent, 2

    it 'defines a "tab_indents" config variable, defaulting to true', ->
      assert.equal config.tab_indents, true

    it 'defines a "backspace_unindents" config variable, defaulting to true', ->
      assert.equal config.backspace_unindents, true

    describe '.tab()', ->
      it 'inserts a tab character if use_tabs is true', ->
        config.use_tabs = true
        buffer.text = 'hƏllo'
        cursor.pos = 2
        editor\tab!
        assert.equal buffer.text, 'h\tƏllo'

      it 'inserts spaces to move to the next tab if use_tabs is false', ->
        config.use_tabs = false
        buffer.text = 'hƏllo'
        cursor.pos = 1
        editor\tab!
        assert.equal buffer.text, string.rep(' ', config.tab_width) .. 'hƏllo'

      it 'inserts a tab move to the next tab if use_tabs is true', ->
        config.use_tabs = true
        buffer.text = 'hƏllo'
        cursor.pos = 1
        editor\tab!
        assert.equal buffer.text, '\thƏllo'

      it 'indents the current line if in whitespace and tab_indents is true', ->
        config.use_tabs = false
        config.tab_indents = true
        indent = string.rep ' ', config.indent
        buffer.text = indent .. 'hƏllo'
        cursor.pos = 2
        editor\tab!
        assert.equal buffer.text, string.rep(indent, 2) .. 'hƏllo'

    describe '.backspace()', ->
      it 'deletes back by one character', ->
        buffer.text = 'hƏllo'
        cursor.pos = 2
        editor\backspace!
        assert.equal buffer.text, 'Əllo'

      it 'unindents if in whitespace and backspace_unindents is true', ->
        config.indent = 2
        buffer.text = '  hƏllo'
        cursor.pos = 3
        config.backspace_unindents = true
        editor\backspace!
        assert.equal buffer.text, 'hƏllo'

      it 'deletes back if in whitespace and backspace_unindents is false', ->
        config.indent = 2
        buffer.text = '  hƏllo'
        cursor.pos = 3
        config.backspace_unindents = false
        editor\backspace!
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
