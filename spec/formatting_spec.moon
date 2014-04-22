import Buffer, formatting from howl
import Editor from howl.ui

describe 'formatting', ->
  local buffer, editor, cursor, lines
  before_each ->
    buffer = Buffer!
    buffer.config.indent = 2
    editor = Editor buffer
    cursor = editor.cursor

  describe 'ensure_block(editor, block_start_p, block_end_p, end_s)', ->
    context 'when block_start_p does not match', ->
      it 'does nothing and returns false', ->
        buffer.text = '{\n}'
        cursor.line = 2
        assert.is_false formatting.ensure_block editor, 'foo', 'bar', 'bar'
        assert.equals '{\n}', buffer.text

    context 'when block_start_p matches', ->
      it 'formats an existing block as necessary', ->
        buffer.text = '{\n}'
        cursor.line = 2
        assert.is_true formatting.ensure_block editor, '{$', '}', '}'
        assert.equals '{\n  \n}', buffer.text
        assert.equals 2, cursor.line

      it 'completes an existing block as necessary', ->
        buffer.text = '{\n'
        cursor.line = 2
        assert.is_true formatting.ensure_block editor, '{$', '}', '}'
        assert.equals '{\n  \n}\n', buffer.text
        assert.equals 2, cursor.line

      it 'is not fooled by subsequent blocks', ->
        buffer.text = '{\n\n{\n}'
        cursor.line = 2
        assert.is_true formatting.ensure_block editor, '{$', '}', '}'
        assert.equals '{\n  \n}\n{\n}', buffer.text
        assert.equals 2, cursor.line

      it 'leaves an already ok indented block alone', ->
        buffer.text = '{\n  \n}\n'
        cursor.line = 2
        assert.is_false formatting.ensure_block editor, '{%s*$', '}', '}'
        assert.equals '{\n  \n}\n', buffer.text
        assert.equals 2, cursor.line

      it 'leaves an already ok non-indented block alone', ->
        buffer.text = '{\n\nfoo\n}\n'
        cursor.line = 2
        assert.is_false formatting.ensure_block editor, '{%s*$', '}', '}'
        assert.equals '{\n\nfoo\n}\n', buffer.text
        assert.equals 2, cursor.line

      it 'leaves blocks with content in them alone', ->
        buffer.text = '{\n  \n  foo\n}\n'
        for line in *{2, 3}
          cursor.line = line
          assert.is_false formatting.ensure_block editor, '{$', '}', '}'
          assert.equals '{\n  \n  foo\n}\n', buffer.text
          assert.equals line, cursor.line

      it 'handles nested blocks', ->
        buffer.text = '{\n  {\n\n}\n'
        cursor.line = 3
        assert.is_true formatting.ensure_block editor, '{$', '}', '}'
        assert.equals '{\n  {\n    \n  }\n}\n', buffer.text
        assert.equals 3, cursor.line

      context 'when block_start_p equals block_end_p', ->
        it 'formats an existing block as necessary', ->
          buffer.text = '|\n|'
          cursor.line = 2
          assert.is_true formatting.ensure_block editor, '|$', '|', '|'
          assert.equals '|\n  \n|', buffer.text
          assert.equals 2, cursor.line

        it 'completes an existing block as necessary', ->
          buffer.text = '|\n'
          cursor.line = 2
          assert.is_true formatting.ensure_block editor, '|$', '|', '|'
          assert.equals '|\n  \n|\n', buffer.text
          assert.equals 2, cursor.line

        it 'leaves an already ok indented block alone', ->
          buffer.text = '|\n  \n|\n'
          cursor.line = 2
          assert.is_false formatting.ensure_block editor, '|$', '|', '|'
          assert.equals '|\n  \n|\n', buffer.text
          assert.equals 2, cursor.line

        it 'leaves an already ok non-indented block alone', ->
          buffer.text = '|\n\nfoo\n|\n'
          cursor.line = 2
          assert.is_false formatting.ensure_block editor, '|$', '|', '|'
          assert.equals '|\n\nfoo\n|\n', buffer.text
          assert.equals 2, cursor.line

        it 'leaves an already ok non-indented block alone', ->
          buffer.text = '|\n\nfoo\n|\n'
          cursor.line = 2
          assert.is_false formatting.ensure_block editor, '|$', '|', '|'
          assert.equals '|\n\nfoo\n|\n', buffer.text
          assert.equals 2, cursor.line

        it 'recognizes a previous block if it is all non-blank lines', ->
          buffer.text = '|\nfoo\n|\n'
          cursor.line = 4
          assert.is_false formatting.ensure_block editor, '|$', '|', '|'
          assert.equals '|\nfoo\n|\n', buffer.text
          assert.equals 4, cursor.line

      context 'indentation & cursor', ->
        it 'indents the new line using the "indent" config variable by default', ->
          buffer.config.indent = 4
          buffer.text = '{\n'
          cursor.line = 2
          formatting.ensure_block editor, '{$', '}', '}'
          assert.equals '{\n    \n}\n', buffer.text

        it 'indents the new line using the editor', ->
          buffer.mode = indent: (editor) => editor.current_line.indentation = 5
          buffer.text = '{\n'
          cursor.line = 2
          formatting.ensure_block editor, '{$', '}', '}'
          assert.equals '{\n     \n}\n', buffer.text

        it 'positions the cursor after the indentation of the new line', ->
          buffer.text = '{\n'
          cursor.line = 2
          assert.is_true formatting.ensure_block editor, '{$', '}', '}'
          assert.equals 3, cursor.column
