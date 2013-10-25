import DefaultMode from howl.modes
import Buffer from howl
import Editor from howl.ui

describe 'DefaultMode', ->
  local buffer, mode, lines
  editor = Editor Buffer {}
  cursor = editor.cursor
  selection = editor.selection

  before_each ->
    buffer = Buffer {}
    mode = DefaultMode!
    buffer.mode = mode
    buffer.config.indent = 2
    lines = buffer.lines
    editor.buffer = buffer

  describe '.indent()', ->
    context 'when .indent_patterns is set', ->
      context 'and the previous line matches one of the patterns', ->
        it 'indents lines below matching lines with the currently set indent', ->
          mode.indent_patterns = { r'if', 'then' }
          buffer.text = 'if\nbar\nthen\nfoo\n'
          selection\select_all!
          mode\indent editor
          assert.equals 'if\n  bar\nthen\n  foo\n', buffer.text

        context 'when .indent_patterns.authoritive is not false', ->
          it 'adjusts lines with unwarranted greater indents to match the previous line', ->
            mode.indent_patterns = { 'if' }
            buffer.text = 'line\n  wat?\n'
            selection\select_all!
            mode\indent editor
            assert.equals 'line\nwat?\n', buffer.text

        context 'when .indent_patterns.authoritive is false', ->
          it 'does not adjust lines with unwarranted greater indents to match the previous line', ->
            mode.indent_patterns = { 'if', authoritive: false }
            buffer.text = 'line\n  wat?\n'
            selection\select_all!
            mode\indent editor
            assert.equals 'line\n  wat?\n', buffer.text

    context 'when .dedent_patterns is set', ->
      context 'and the current line matches one of the patterns', ->
        it 'dedents the line one level below the previous line if it exists', ->
          mode.dedent_patterns = { r'else', '}' }
          buffer.text = '    bar\n    else\n  foo\n  }\n'
          selection\select_all!
          mode\indent editor
          assert.equals '    bar\n  else\n  foo\n}\n', buffer.text

        context 'when .dedent_patterns.authoritive is not false', ->
          it 'adjusts lines with unwarranted smaller indents to match the previous line', ->
            mode.dedent_patterns = { 'else' }
            buffer.text = '  line\nwat?\n'
            selection\select_all!
            mode\indent editor
            assert.equals '  line\n  wat?\n', buffer.text

        context 'when .dedent_patterns.authoritive is false', ->
          it 'does not adjust lines with unwarranted smaller indents to match the previous line', ->
            mode.dedent_patterns = { 'else', authoritive: false }
            buffer.text = '  line\nwat?\n'
            selection\select_all!
            mode\indent editor
            assert.equals '  line\nwat?\n', buffer.text

    context 'when both .dedent_patterns and .indent_patterns are set', ->
      it 'they cancel out each other when both match', ->
        mode.indent_patterns = { '{' }
        mode.dedent_patterns = { '}' }
        buffer.text = '  {\n  }'
        selection\select_all!
        mode\indent editor
        assert.equals '  {\n  }', buffer.text

    it 'sets the same indent as for the previous line if the line is blank', ->
      buffer.text = '  line\n\n'
      selection\select_all!
      mode\indent editor
      assert.equals '  line\n  \n', buffer.text

    it 'adjust any illegal indentation (not divisable by indent)', ->
      buffer.text = '  line\n two\n'
      selection\select_all!
      mode\indent editor
      assert.equals '  line\n  two\n', buffer.text

    it 'works on the current line if no selection is specified', ->
      mode.indent_patterns = { 'if' }
      buffer.text = 'if\none\ntwo\n'
      cursor.line = 2
      mode\indent editor
      assert.equals 'if\n  one\ntwo\n', buffer.text

    it 'moves the cursor to the beginning of indentation if it would be positioned before', ->
      buffer.text = '  line\n\n'
      cursor.line = 2
      mode\indent editor
      assert.equals '  line\n  \n', buffer.text
      assert.equals 3, cursor.column

  describe 'comment(editor)', ->
    text = [[
  liñe 1

    liñe 2
    liñe 3
  ]]
    before_each ->
      buffer.text = text
      selection\set 1, lines[4].start_pos

    context 'when .short_comment_prefix is not set', ->
      it 'does nothing', ->
        mode\comment editor
        assert.equal text, buffer.text

    context 'when .short_comment_prefix is set', ->
      before_each -> mode.short_comment_prefix = '--'

      it 'prefixes the selected lines with the prefix and a space, at the minimum indentation level', ->
        mode\comment editor
        assert.equal [[
  -- liñe 1

  --   liñe 2
    liñe 3
  ]], buffer.text

      it 'comments the current line if nothing is selected', ->
        selection\remove!
        cursor.pos = 1
        mode\comment editor
        assert.equal [[
  -- liñe 1

    liñe 2
    liñe 3
  ]], buffer.text

      it 'keeps the cursor position', ->
        editor.selection.cursor = lines[3].start_pos + 2
        mode\comment editor
        assert.equal 6, cursor.column

  describe 'uncomment(editor)', ->
    text = [[
  --  liñe 1
    -- -- liñe 2
    --liñe 3
]]
    before_each ->
      buffer.text = text
      selection\set 1, lines[3].start_pos

    context 'when .short_comment_prefix is not set', ->
      it 'does nothing', ->
        mode\uncomment editor
        assert.equal text, buffer.text

    context 'when .short_comment_prefix is set', ->
      before_each -> buffer.mode.short_comment_prefix = '--'

      it 'removes the first instance of the comment prefix and optional space from each line', ->
        mode\uncomment editor
        assert.equal [[
   liñe 1
    -- liñe 2
    --liñe 3
]], buffer.text

      it 'uncomments the current line if nothing is selected', ->
        selection\remove!
        cursor.line = 2
        mode\uncomment editor
        assert.equal [[
  --  liñe 1
    -- liñe 2
    --liñe 3
]], buffer.text

      it 'keeps the cursor position', ->
        editor.selection.cursor = lines[2].start_pos + 6
        mode\uncomment editor
        assert.equal 4, cursor.column

      it 'does nothing for lines that are not commented', ->
        buffer.text = "line\n"
        cursor.line = 1
        mode\uncomment editor
        assert.equal "line\n", buffer.text

  describe 'toggle_comment(editor)', ->
    context 'when mode does not provide .short_comment_prefix', ->
      it 'does nothing', ->
        buffer.text = '-- foo'
        mode\toggle_comment editor
        assert.equal '-- foo', buffer.text

    context 'when mode provides .short_comment_prefix', ->
      before_each -> buffer.mode.short_comment_prefix = '--'

      it 'it uncomments if the first line starts with the comment prefix', ->
        buffer.text = '  -- foo'
        mode\toggle_comment editor
        assert.equal '  foo', buffer.text

      it 'comments if the first line do no start with the comment prefix', ->
        buffer.text = 'foo'
        mode\toggle_comment editor
        assert.equal '-- foo', buffer.text

  describe 'auto-formatting after newline', ->
    it 'indents the new line automatically given the indent patterns', ->
      mode.indent_patterns = { 'if' }
      buffer.text = 'if'
      cursor\eof!
      editor\newline!
      assert.equals 'if\n  ', buffer.text

      buffer.text = 'other'
      cursor\eof!
      editor\newline!
      assert.equals 'other\n', buffer.text

  describe 'structure()', ->
    assert_lines = (expected, actual) -> assert.same [l.nr for l in *expected], [l.nr for l in *actual]

    it 'returns a simple indentation-based structure', ->
      buffer.text = [[
        header1
          sub1
            foo
            bar
            zed
            froz
        header2
          sub2
      ]]
      assert_lines {
        lines[1]
        lines[2]
        lines[7]
      }, mode\structure editor

    it 'the config variable indentation_structure_threshold determines when it stops', ->
      buffer.text = [[
        header1
          sub1
            froz
        header2
          sub2
      ]]
      buffer.config.indentation_structure_threshold = 2
      assert_lines { lines[1], lines[4] }, mode\structure editor

    it 'disregards blank lines', ->
      buffer.text = '\n  sub\n'
      assert.same {}, mode\structure editor

    context 'if a structure line is all non-alpha', ->
      it 'tries to use the previous line if that contains alpha characters', ->
        buffer.text = [[
          int func(int arg)
          {
            froz();
          }
        ]]
        assert_lines { lines[1] }, mode\structure editor

      it 'skips the line altogether if the previous line does not contain alpha characters', ->
        buffer.text = [[

          {
            froz();
          }
        ]]
        assert_lines {}, mode\structure editor

  context 'when return is pressed', ->
    it 'sets the indentation for the newl line to the indentation of the previous non-blank line', ->
      buffer.text = '  line1\n\nline3'
      cursor.line = 3
      editor\newline!
      assert.equals 2, editor.current_line.indentation
