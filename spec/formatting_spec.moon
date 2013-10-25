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
        assert.equals 3, cursor.column

      it 'completes an existing block as necessary', ->
        buffer.text = '{\n'
        cursor.line = 2
        assert.is_true formatting.ensure_block editor, '{$', '}', '}'
        assert.equals '{\n  \n}\n', buffer.text
        assert.equals 2, cursor.line
        assert.equals 3, cursor.column

      it 'it leaves an already ok block alone', ->
        buffer.text = '{\n  \n}\n'
        cursor.line = 2
        assert.is_false formatting.ensure_block editor, '{%s*$', '}', '}'
        assert.equals '{\n  \n}\n', buffer.text
        assert.equals 2, cursor.line

      it 'it leaves blocks with content in them alone', ->
        buffer.text = '{\n  \n  foo\n}\n'
        for line in *{2, 3}
          cursor.line = line
          assert.is_false formatting.ensure_block editor, '{$', '}', '}'
          assert.equals '{\n  \n  foo\n}\n', buffer.text
          assert.equals line, cursor.line
