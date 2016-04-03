import DefaultMode from howl.modes
import Buffer from howl
import Editor, ActionBuffer from howl.ui

describe 'DefaultMode', ->
  local buffer, mode, lines, indentation
  editor = Editor Buffer {}
  cursor = editor.cursor
  selection = editor.selection

  indent = ->
    selection\select_all!
    mode\indent editor

  before_each ->
    buffer = Buffer {}
    mode = DefaultMode!
    indentation = {}
    mode.indentation = indentation
    buffer.mode = mode
    buffer.config.indent = 2
    lines = buffer.lines
    editor.buffer = buffer

  describe '.indent()', ->
    context 'when .indentation.more_after patterns is set', ->
      context 'and the previous line matches one of the patterns', ->
        it 'indents lines below matching lines with the currently set indent', ->
          indentation.more_after = { r'if', 'then' }
          buffer.text = 'if\nbar\nthen\nfoo\n'
          indent!
          assert.equals 'if\n  bar\nthen\n  foo\n', buffer.text

        context 'when .authoritive is not false', ->
          it 'adjusts lines with unwarranted greater indents to match the previous line', ->
            indentation.more_after = { 'if' }
            buffer.text = 'line\n  wat?\n'
            indent!
            assert.equals 'line\nwat?\n', buffer.text

        context 'when .authoritive is false', ->
          it 'does not adjust lines with unwarranted greater indents to match the previous line', ->
            indentation.more_after = { 'if', authoritive: false }
            buffer.text = 'line\n  wat?\n'
            indent!
            assert.equals 'line\n  wat?\n', buffer.text

    context 'when .indentation.less_for is set', ->
      context 'and the current line matches one of the patterns', ->
        it 'dedents the line one level below the previous line if it exists', ->
          indentation.less_for = { r'else', '}' }
          buffer.text = '    bar\n    else\n  foo\n  }\n'
          indent!
          assert.equals '    bar\n  else\n  foo\n}\n', buffer.text

        context 'when .authoritive is not false', ->
          it 'adjusts lines with unwarranted smaller indents to match the previous line', ->
            indentation.less_for = { 'else' }
            buffer.text = '  line\nwat?\n'
            indent!
            assert.equals '  line\n  wat?\n', buffer.text

        context 'when .authoritive is false', ->
          it 'does not adjust lines with unwarranted smaller indents to match the previous line', ->
            indentation.less_for = { 'else', authoritive: false }
            buffer.text = '  line\nwat?\n'
            indent!
            assert.equals '  line\nwat?\n', buffer.text

    context 'when .indentation.more_for is set', ->
      context 'and the current line matches one of the patterns', ->
        it 'indents the line one level right of the previous line if it exists', ->
          indentation.more_for = { '^.' }
          buffer.text = 'bar\n.foo\n'
          indent!
          assert.equals 'bar\n  .foo\n', buffer.text

    context 'when .indentation.same_after patterns is set', ->
      context 'and the previous line matches one of the patterns', ->
        it 'indents lines below matching lines to have the same indent as the previous line', ->
          indentation.same_after = ',$'
          buffer.text = '  foo,\nbar'
          indent!
          assert.equals '  foo,\n  bar', buffer.text

    context 'when more than one of .less_for, .more_after or .same_after are set', ->
      it 'they are weighed together', ->
        indentation.more_after = { '{' }
        indentation.less_for = { '}' }
        indentation.same_after = { ',$' }
        buffer.text = '  {\n  }'
        indent!
        assert.equals '  {\n  }', buffer.text

        buffer.text = '  {\n  foo,}'
        indent!
        assert.equals '  {\n  foo,}', buffer.text

    it 'does not try to indent lines within comments or strings', ->
        indentation.more_after = { '{' }
        indentation.less_for = { '}' }
        buffer = ActionBuffer!
        buffer.text = '{\nfoo\n  }\n'
        lines = buffer.lines
        buffer\style lines[1].start_pos, lines[2].end_pos, 'comment'
        buffer\style lines[3].start_pos, lines[4].end_pos, 'string'
        editor.buffer = buffer
        indent!
        assert.equals '{\nfoo\n  }\n', buffer.text

    it 'uses the same indent as for the previous line if it is a comment', ->
        indentation.more_after = { '{' }
        mode.comment_syntax = '#'
        buffer.text = "  # I'm commenting thank you very much {\n# and still are\n"
        indent!
        assert.equals 2, lines[2].indentation

    context 'when a line is blank', ->
      it 'does not indent unless it is the current line', ->
          indentation.more_after = { '{' }
          indentation.less_for = { '}' }
          buffer.text = '{\n\n}'
          indent!
          assert.equals '{\n\n}', buffer.text

      context 'and it is the current line', ->

        it 'indents according to patterns', ->
            indentation.more_after = { '{' }
            indentation.less_for = { '}' }
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
      indentation.more_after = { 'if' }
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

  describe 'comment(editor, lines)', ->
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

      it 'comments the given lines', ->
        editor.selection\remove!
        mode\comment editor, editor.buffer.lines\for_text_range 1, 12
        assert.equal [[
  /* liñe 1 */

  /*   liñe 2 */
    liñe 3
  ]], buffer.text

  describe 'uncomment(editor, lines)', ->

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

    it 'comments the given lines', ->
      buffer.mode.comment_syntax = '--'
      buffer.text = '-- foo\n-- bar\n-- baz'
      mode\uncomment editor, editor.buffer.lines\for_text_range 1, 9
      assert.equal 'foo\nbar\n-- baz', buffer.text

  describe 'toggle_comment(editor, lines)', ->
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
      indentation.more_after = { 'if' }
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

  describe 'when a newline is added', ->
    it 'sets the indentation for the new line to the indentation of the previous non-blank line', ->
      buffer.text = '  34\n\n78'
      cursor.pos = 7
      editor\newline!
      assert.equals 2, editor.current_line.indentation

    context 'when .code_blocks.multiline is present', ->
      it 'the code blocks are automatically enforced', ->
        mode.code_blocks = multiline: {
          { '%sdo$', '^%s*end', 'end' },
        }
        buffer.text = 'foo do'
        cursor\eof!
        editor\newline!
        assert.equals 'foo do\n\nend\n', buffer.text
        assert.equals 2, cursor.line

      it 'is ignored if the configuration variable "auto_format" is false', ->
        buffer.config.auto_format = false
        mode.code_blocks = multiline: {
          { '%sdo$', '^%s*end', 'end' },
        }
        buffer.text = 'foo do'
        cursor\eof!
        editor\newline!
        assert.equals 'foo do\n', buffer.text
