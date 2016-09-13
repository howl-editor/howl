import bundle, mode, Buffer from howl
import Editor from howl.ui

require 'howl.variables.core_variables'

describe 'lisp-mode', ->
  local m
  local buffer, editor, cursor, lines

  setup ->
    bundle.load_by_name 'lisp'
    m = mode.by_name 'lisp'

  teardown -> bundle.unload 'lisp'

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
      buffer.text = '(defn foo\n'
      cursor.line = 2
      editor\indent!
      assert.equal indent_level, editor.current_line.indentation

    it 'indents from the last unmatched parenthesis', ->
      buffer.text = '(defn (foo\n'
      cursor.line = #lines
      editor\indent!
      assert.equal 8, editor.current_line.indentation

    it 'indents from the last expression', ->
      buffer.text = '(defn bar\n  (foo\n    (z)))\n'
      cursor.line = #lines
      editor\indent!
      assert.equal 0, editor.current_line.indentation

    it 'aligns with the quote for quoted lists', ->
      buffer.text = "(defn '(foo\n"
      cursor.line = 2
      editor\indent!
      assert.equal 8, editor.current_line.indentation

    it 'aligns with unmatched opening brackets', ->
      buffer.text = '(let [foo (bar)\n'
      cursor.line = 2
      editor\indent!
      assert.equal 6, editor.current_line.indentation

    it 'aligns with any subsequent forms following an opening bracket', ->
      buffer.text = '[xyz [\n  [a b]\n'
      cursor.line = 3
      editor\indent!
      assert.equal 2, editor.current_line.indentation

    it 'shrewdly avoids misaligning with any subsequent forms to far away', ->
      for ex in *{ '(defn list-me ()\n', '(fn []\n' }
        buffer.text = ex
        cursor.line = 2
        editor\indent!
        assert.equal 2, editor.current_line.indentation

    it 'corrects any incorrect indentation level', ->
      buffer.text = '  foo\n   bar'
      cursor.line = 2
      editor\indent!
      assert.equal 2, editor.current_line.indentation
