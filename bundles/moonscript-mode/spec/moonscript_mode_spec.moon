import bundle, mode, config, Buffer from howl
import File from howl.fs
import Editor from howl.ui

describe 'moonscript-mode', ->
  local m
  local buffer, editor, cursor, lines

  setup ->
    bundle.load_by_name 'moonscript-mode'
    m = mode.by_name 'moonscript'

  teardown -> bundle.unload 'moonscript-mode'

  before_each ->
    m = mode.by_name 'moonscript'
    buffer = Buffer m
    editor = Editor buffer
    cursor = editor.cursor
    lines = buffer.lines

  it 'registers a mode', ->
    assert.not_nil m

  it 'handles .moon files', ->
    assert.equal mode.for_file(File 'test.moon'), m

  describe 'indentation support', ->
    indent_level = 2

    before_each ->
      buffer.config.indent = indent_level

    indents = {
      'pending function definitions': {
        'foo: =>',
        'foo: -> '
      }
      'pending class declarations': {
        'class Frob',
        'class Frob  ',
        'class Frob extends Bar ',
      }
      'hanging assignments': {
        'var = ',
        'var: ',
      }
     'open bracket statements': {
        'var = { ',
        'var = {',
        'other: {',
        'some(',
        '{'
      }
      'open conditionals': {
        'if foo and bar',
        'else',
        'elseif (foo and bar) or frob',
        'elseif true',
        'while foo',
        'unless bar',
      }
      'block statements': {
        'switch foo!'
        'do',
        'for i = 1,10',
        'with some.object',
        'when conditional',
        'foo = if bar and frob'
      }
    }

    non_indents = {
      'closed conditionals': {
        'if foo then bar',
        'elseif foo then bar',
        'unless foo then bar',
        'bar unless foo',
        'else bar',
      },
      'statement modifiers': {
        'foo! if bar',
        'foo! unless bar',
      }
      'miscellaneous non-indenting statements': {
        'foo = bar',
        'foo = bar frob zed'
        'foo = not bar(frob zed)'
        'ado',
        'fortwith bar'
        'motif some'
        'iffy!'
        'dojo_style foo'
        'one for two'
      }
    }

    dedents = {
      'block starters': {
        'else',
        'elseif foo',
      }
      'block enders': {
        '}',
      }
    }

    for desc in pairs indents
      context 'indents one level for a line after ' .. desc, ->
        for code in *indents[desc]
          it "e.g. indents for '#{code}'", ->
            buffer.text = code .. '\n'
            cursor.line = 2
            editor\indent!
            assert.equal indent_level, editor.current_line.indentation

    it 'disregards empty lines above when determining indent', ->
      for desc in pairs indents
        for code in *indents[desc]
          buffer.text = code .. '\n\n'
          cursor.line = 3
          editor\indent!
          assert.equal indent_level, editor.current_line.indentation

    for desc in pairs dedents
      context 'dedents one level for a line containing ' .. desc, ->
        for code in *dedents[desc]
          it "e.g. dedents for '#{code}'", ->
            buffer.text = '  foo\n  ' .. code
            cursor.line = 2
            editor\indent!
            assert.equal 0, editor.current_line.indentation

    for desc in pairs non_indents
      context 'keeps the current indent for a line after ' .. desc, ->
        for code in *non_indents[desc]
          it "e.g. does not indent for '#{code}'", ->
            buffer.text = "  #{code}\n  "
            cursor.line = 2
            editor\indent!
            assert.equal 2, editor.current_line.indentation

    it 'returns a corrected indent for lines that are on incorrect indentation', ->
      buffer.text = '  bar\n one_column_offset'
      cursor.line = 2
      editor\indent!
      assert.equal 2, editor.current_line.indentation

    it 'returns the indent for the previous line for a line with a non-motivated greater indent', ->
      buffer.text = 'bar\n  foo'
      cursor.line = 2
      editor\indent!
      assert.equal 0, editor.current_line.indentation

    it 'keeps the indent for lines when if nothing particular is known', ->
      buffer.text = '  foo\nbar'
      cursor.line = 2
      editor\indent!
      assert.equal 0, editor.current_line.indentation

    it 'returns the indent for the previous line for a blank line', ->
      buffer.text = '  bar\n'
      cursor.line = 2
      editor\indent!
      assert.equal 2, editor.current_line.indentation

  describe 'structure(editor)', ->
    it 'returns lines that match class and function declarations', ->
      buffer.text = [[
bar = -> true
foo = ->
  true
but_this_passes_a_callback ->
  'no'
also = a_callback ->
class Foo
  new: (frob) =>
    nil
  other: =>
    'this one to'
  class_f: ->
    'oh yeah'
]]

      expected = [[
bar = -> true
foo = ->
class Foo
  new: (frob) =>
  other: =>
  class_f: ->
]]
      assert.equal expected.stripped, table.concat [tostring(l) for l in *m\structure(editor)], '\n'

    it 'always includes the parent line of an included line', ->
      buffer.text = [[
take_me! {

  foo: -> 'voila'
}
]]
      assert.same {1, 3}, [l.nr for l in *m\structure editor]

    it 'falls back to the parent structure method if nothing is found', ->
      buffer.text = [[
foo {
  bar: 1
  frob:
    zed: 2
}
]]
      assert.same {1, 3}, [l.nr for l in *m\structure editor]
