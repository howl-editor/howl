import bundle, mode, config, Buffer from howl
import File from howl.fs
import Editor from howl.ui

describe 'lisp-mode', ->
  local m
  local buffer, editor, cursor, lines

  setup ->
    bundle.load_by_name 'lisp-mode'
    m = mode.by_name 'lisp'

  teardown -> bundle.unload 'lisp-mode'

  before_each ->
    buffer = Buffer m
    editor = Editor buffer
    cursor = editor.cursor
    lines = buffer.lines

  it 'registers a mode', ->
    assert.not_nil m

  describe 'indentation support', ->
    indent_level = 2

    before_each ->
      buffer.config.indent = indent_level

    it 'indents when the previous line has more opening than closing parentheses', ->
      for ex in *{ '(defn foo\n', '(inv (bar)\n' }
        buffer.text = ex
        cursor.line = 2
        editor\indent!
        assert.equal indent_level, editor.current_line.indentation

    it 'dedents when the previous line has more closing than opening parentheses', ->
      for ex in *{ '  (bar foo))\n', '  bar)\n' }
        buffer.text = ex
        cursor.line = 2
        editor\indent!
        assert.equal 0, editor.current_line.indentation

    it 'corrects any incorrect indentation level', ->
      buffer.text = '  foo\n   bar'
      cursor.line = 2
      editor\indent!
      assert.equal 2, editor.current_line.indentation
