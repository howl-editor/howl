import bundle, mode, Buffer from howl
import Editor from howl.ui

describe 'html mode', ->
  local m
  local buffer, editor, cursor
  indent_level = 2

  setup ->
    bundle.load_by_name 'html'
    m = mode.by_name 'html'

  teardown -> bundle.unload 'html'

  before_each ->
    m = mode.by_name 'html'
    buffer = Buffer m
    buffer.config.indent = indent_level
    editor = Editor buffer
    cursor = editor.cursor

  context 'indentation', ->
    indent_for = (text, line) ->
      buffer.text = text
      cursor.line = line
      editor\indent!
      editor.current_line.indentation

    it 'indents after ordinary tags', ->
      for text in *{
        '<p>\n',
        '<div id="myid">\n',
        '<annotation encoding="text/latex">\n'
      }
        assert.equal indent_level, indent_for text, 2

    it 'dedents closing tags', ->
      assert.equal 0, indent_for '  foo\n  </p>', 2

    it 'dedents closing tags', ->
      assert.equal 0, indent_for '  foo\n  </p>', 2

    it 'does not indent after closed tags', ->
      assert.equal 0, indent_for '<p>Hello world!</p>\n', 2

    it 'does not indent after certain void element tags', ->
      for text in *{ '<br>\n', '<input type="checkbox">\n' }
        assert.equal 0, indent_for text, 2
