import DefaultMode from howl.modes
import Buffer from howl
import Editor, ActionBuffer from howl.ui

describe 'DefaultMode', ->
  local buffer, mode, lines
  editor = Editor Buffer {}
  cursor = editor.cursor
  selection = editor.selection

  indent = ->
    selection\select_all!
    mode\indent editor

  before_each ->
    buffer = Buffer {}
    mode = DefaultMode!
    buffer.mode = mode
    buffer.config.indent = 2
    lines = buffer.lines
    editor.buffer = buffer

  describe '.indent()', ->
    context 'when .indent_after_patterns is set', ->
      context 'and the previous line matches one of the patterns', ->
        it 'indents lines below matching lines with the currently set indent', ->
          mode.indent_after_patterns = { r'if', 'then' }
          buffer.text = 'if\nbar\nthen\nfoo\n'
          indent!
          assert.equals 'if\n  bar\nthen\n  foo\n', buffer.text

        context 'when .indent_after_patterns.authoritive is not false', ->
          it 'adjusts lines with unwarranted greater indents to match the previous line', ->
            mode.indent_after_patterns = { 'if' }
            buffer.text = 'line\n  wat?\n'
            indent!
            assert.equals 'line\nwat?\n', buffer.text

        context 'when .indent_after_patterns.authoritive is false', ->
          it 'does not adjust lines with unwarranted greater indents to match the previous line', ->
            mode.indent_after_patterns = { 'if', authoritive: false }
            buffer.text = 'line\n  wat?\n'
            indent!
            assert.equals 'line\n  wat?\n', buffer.text

    context 'when .dedent_patterns is set', ->
      context 'and the current line matches one of the patterns', ->
        it 'dedents the line one level below the previous line if it exists', ->
          mode.dedent_patterns = { r'else', '}' }
          buffer.text = '    bar\n    else\n  foo\n  }\n'
          indent!
          assert.equals '    bar\n  else\n  foo\n}\n', buffer.text

        context 'when .dedent_patterns.authoritive is not false', ->
          it 'adjusts lines with unwarranted smaller indents to match the previous line', ->
            mode.dedent_patterns = { 'else' }
            buffer.text = '  line\nwat?\n'
            indent!
            assert.equals '  line\n  wat?\n', buffer.text

        context 'when .dedent_patterns.authoritive is false', ->
          it 'does not adjust lines with unwarranted smaller indents to match the previous line', ->
            mode.dedent_patterns = { 'else', authoritive: false }
            buffer.text = '  line\nwat?\n'
            indent!
            assert.equals '  line\nwat?\n', buffer.text

    context 'when both .dedent_patterns and .indent_after_patterns are set', ->
      it 'they cancel out each other when both match', ->
        mode.indent_after_patterns = { '{' }
        mode.dedent_patterns = { '}' }
        buffer.text = '  {\n  }'
        indent!
        assert.equals '  {\n  }', buffer.text

    it 'does not try to indent lines within comments or strings', ->
        mode.indent_after_patterns = { '{' }
        mode.dedent_patterns = { '}' }
        buffer = ActionBuffer!
        buffer.text = '{\nfoo\n  }\n'
        lines = buffer.lines
        buffer\style lines[1].start_pos, lines[2].end_pos, 'comment'
        buffer\style lines[3].start_pos, lines[4].end_pos, 'string'
        editor.buffer = buffer
        indent!
        assert.equals '{\nfoo\n  }\n', buffer.text

    it 'uses the same indent as for the previous line if it is a comment', ->
        mode.indent_after_patterns = { '{' }
        mode.comment_syntax = '#'
        buffer.text = "  # I'm commenting thank you very much {\n# and still are\n"
        indent!
        assert.equals 2, lines[2].indentation

    context 'when a line is blank', ->
      it 'does not indent unless it is the current line', ->
          mode.indent_after_patterns = { '{' }
          mode.dedent_patterns = { '}' }
          buffer.text = '{\n\n}'
          indent!
          assert.equals '{\n\n}', buffer.text

      context 'and it is the current line', ->

        it 'indents according to patterns', ->
            mode.indent_after_patterns = { '{' }
            mode.dedent_patterns = { '}' }
            buffer.text = '{\n\n}'
            cursor.line = 2
            mode\indent editor
            assert.equals '{\n  \n}', buffer.text

        it 'sets the same indent as for the previous line if nothing else is specified', ->
          buffer.text = '  line\n\n'
          cursor.line = 2
          mode\indent editor
          assert.equals '  line\n  \n', buffer.text

    it 'adjust any illegal indentation (not divisable by indent)', ->
      buffer.text = '  line\n two\n'
      indent!
      assert.equals '  line\n  two\n', buffer.text

    it 'works on the current line if no selection is specified', ->
      mode.indent_after_patterns = { 'if' }
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

    context 'when .comment_syntax is not set', ->
      it 'does nothing', ->
        mode\comment editor
        assert.equal text, buffer.text

    context 'when .comment_syntax is set to a string', ->
      before_each -> mode.comment_syntax = '--'

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

    context 'when .comment_syntax is set to a pair', ->
      before_each -> mode.comment_syntax = {'/*', '*/'}

      it 'wraps each selected line with the pair, at the minimum indentation level', ->
        mode\comment editor
        assert.equal [[
  /* liñe 1 */

  /*   liñe 2 */
    liñe 3
  ]], buffer.text

      it 'comments the current line if nothing is selected', ->
        selection\remove!
        cursor.pos = 1
        mode\comment editor
        assert.equal [[
  /* liñe 1 */

    liñe 2
    liñe 3
  ]], buffer.text

      it 'keeps the cursor position', ->
        editor.selection.cursor = lines[3].start_pos + 2
        mode\comment editor
        assert.equal 6, cursor.column

  describe 'uncomment(editor)', ->

    context 'when .comment_syntax is not set', ->
      it 'does nothing', ->
        buffer.text = 'foo\nbar\n'
        selection\set 1, lines[2].start_pos
        mode\uncomment editor
        assert.equal 'foo\nbar\n', buffer.text

    context 'when .comment_syntax is set to a string', ->
      before_each ->
        buffer.mode.comment_syntax = '--'
        buffer.text = [[
  --  liñe 1
    -- -- liñe 2
    --liñe 3
]]
        selection\set 1, lines[3].start_pos

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

    context 'when .comment_syntax is set to a pair', ->
      before_each ->
        buffer.mode.comment_syntax = {'/*', '*/'}
        buffer.text = [[
  /*  liñe 1 */
    /* liñe 2 */
    /*liñe 3*/
]]
        selection\set 1, lines[3].start_pos

      it 'removes the first instance of the comment prefix and optional space from each line', ->
        mode\uncomment editor
        assert.equal [[
   liñe 1
    liñe 2
    /*liñe 3*/
]], buffer.text

      it 'uncomments the current line if nothing is selected', ->
        selection\remove!
        cursor.line = 2
        mode\uncomment editor
        assert.equal [[
  /*  liñe 1 */
    liñe 2
    /*liñe 3*/
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
    context 'when mode does not provide .comment_syntax', ->
      it 'does nothing', ->
        buffer.text = '-- foo'
        mode\toggle_comment editor
        assert.equal '-- foo', buffer.text

    context 'when mode provides .comment_syntax', ->
      before_each -> buffer.mode.comment_syntax = '--'

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
      mode.indent_after_patterns = { 'if' }
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

  describe 'patterns_match(text, patterns)', ->
    it 'returns a boolean indicating whether <text> matches any of the specified patterns', ->
      assert.is_true mode\patterns_match 'foo', { 'foo' }
      assert.is_false mode\patterns_match 'foo', { 'bar' }

    it 'accepts both Lua patterns and regexes', ->
      assert.is_true mode\patterns_match 'foo', { 'fo+' }
      assert.is_true mode\patterns_match 'foo', { r'\\pLo*' }

    it 'a specifed pattern can be table containing both a positiv and a negative match', ->
      p = { 'foo', 'bar' }
      assert.is_true mode\patterns_match 'foo zed', { p }
      assert.is_false mode\patterns_match 'foo bar', { p }

  context 'when return is pressed', ->
    it 'sets the indentation for the newl line to the indentation of the previous non-blank line', ->
      buffer.text = '  line1\n\nline3'
      cursor.line = 3
      editor\newline!
      assert.equals 2, editor.current_line.indentation
