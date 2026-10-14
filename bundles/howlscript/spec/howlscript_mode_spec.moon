import bundle, mode, Buffer from howl
import File from howl.io
import Editor from howl.ui

describe 'howlscript-mode', ->
  local m
  local buffer, editor, cursor

  setup ->
    bundle.load_by_name 'lua'
    bundle.load_by_name 'howlscript'

  teardown ->
    bundle.unload 'howlscript'
    bundle.unload 'lua'

  before_each ->
    m = mode.by_name 'howlscript'
    buffer = Buffer m
    editor = Editor buffer
    cursor = editor.cursor

  it 'registers a mode', ->
    assert.not_nil m

  it 'handles .howl files', ->
    assert.equal mode.for_file(File 'test.howl'), m

  it 'inspects the buffer with the howlscript inspector when idle', ->
    assert.same { 'howlscript' }, buffer.config.inspectors_on_idle

  describe 'indentation support', ->
    indent_level = 2

    before_each ->
      buffer.config.indent = indent_level

    indents = {
      'pending function definitions': {
        'foo: =>',
        'foo: -> '
        'handler: (x) ->'
      }
      'pending class declarations': {
        'class Frob',
        'class Frob extends Bar ',
      }
      'hanging assignments': {
        'var = ',
        'var: ',
      }
      'open bracket statements': {
        'var = { ',
        'other: {',
        'some(',
        'foo(a, ',
        '{'
      }
      'open conditionals': {
        'if foo and bar',
        'else',
        'elseif (foo and bar) or frob',
        'while foo',
        'unless bar',
      }
      'block statements': {
        'switch foo()'
        'do',
        'for i = 1, 10',
        'for x in *items',
        'with some.object',
        'when conditional',
      }
      'blocks used as values': {
        'foo = if bar and frob'
        'foo = switch bar'
        'foo = with Bar()'
        'foo = for x in *list'
        'foo = do'
      }
    }

    non_indents = {
      'closed conditionals': {
        'if foo then bar()',
        'elseif foo then bar()',
        'unless foo then bar()',
        'else bar()',
      }
      'loops with their body after do': {
        'for i = 1, 3 do sum += i'
        'while busy() do wait()'
        'doubled = for x in *list do x * 2'
      }
      'decorated statements': {
        'foo() if bar',
        'foo() unless bar',
        'print(x) for x in *items',
      }
      'miscellaneous non-indenting statements': {
        'foo = bar',
        'foo = not bar(frob, zed)'
        'ado',
        'fortwith(bar)'
        'iffy()'
        'dojo_style(foo)'
        'one(for_two)'
      }
    }

    dedents = {
      'block starters': {
        'else',
        'elseif foo',
      }
      'block enders': {
        '}',
        ')',
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

    it 'enforces the same indent after ","', ->
      buffer.text = "  foo,\nbar"
      cursor.line = 2
      editor\indent!
      assert.equal 2, editor.current_line.indentation

  describe 'structure(editor)', ->
    it 'returns lines that match class, function and spec declarations', ->
      buffer.text = [[
bar = -> true
foo = ->
  true
but_this_passes_a_callback(->
  'no'
)
class Foo
  new: (frob) =>
    nil
  other: =>
    'this one to'
describe('thing', ->
  it('works', ->
    assert.is_true(true)
  )
)
]]

      expected = [[
bar = -> true
foo = ->
class Foo
  new: (frob) =>
  other: =>
describe('thing', ->
  it('works', ->
]]
      assert.equal expected.stripped, table.concat [tostring(l) for l in *m\structure(editor)], '\n'

    it 'falls back to the parent structure method if nothing is found', ->
      buffer.text = [[
foo({
  bar: 1
  frob:
    zed: 2
})
]]
      assert.same {1, 3}, [l.nr for l in *m\structure editor]
