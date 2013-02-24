import bundle, mode, config, Buffer from howl
import File from howl.fs
import Editor from howl.ui

describe 'moonscript-mode', ->
  local m

  setup ->
    bundle.load_by_name 'moonscript-mode'
    m = mode.by_name 'moonscript'

  teardown -> bundle.unload 'moonscript-mode'

  it 'registers a mode', ->
    assert.not_nil m

  it 'handles .moon files', ->
    assert.equal mode.for_file(File 'test.moon'), m

  describe '.indent_for(line, indent_level, editor)', ->
    buffer = Buffer m
    editor = Editor buffer
    cursor = editor.cursor
    lines = buffer.lines
    indent_level = 2
    config.set 'indent', indent_level, buffer

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
      },
      'open conditionals': {
        'if foo and bar',
        'else',
        'elseif (foo and bar) or frob',
        'elseif true',
        'while foo',
        'unless bar',
      },
      'block statements': {
        'switch foo!'
        'do',
        'for i = 1,10'
        'with some.object'
        'when conditional'
      }
    }

    non_indents = {
      'closed conditionals': {
        'if foo then bar', 'elseif foo then bar',
        'unless foo then bar',
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
      context 'returns a one level indent for a line after ' .. desc, ->
        for code in *indents[desc]
          it "e.g. indents for '#{code}'", ->
            buffer.text = code .. '\n'
            cursor.line = 2
            assert.equal indent_level, m\indent_for(lines[2], indent_level, editor)

    it 'disregards empty lines above when determining indent', ->
      for desc in pairs indents
        for code in *indents[desc]
          buffer.text = code .. '\n\n'
          cursor.line = 3
          assert.equal indent_level, m\indent_for(lines[3], indent_level, editor)

    it 'does not disregard blank lines above when determining indent', ->
      for desc in pairs indents
        for code in *indents[desc]
          buffer.text = "  #{code}'\n  \n  "
          cursor.line = 3
          assert.equal 2, m\indent_for(lines[3], indent_level, editor)

    for desc in pairs dedents
      context 'returns a one level dedent for a line containing ' .. desc, ->
        for code in *dedents[desc]
          it "e.g. dedents for '#{code}'", ->
            buffer.text = '  foo\n  ' .. code

            cursor.line = 2
            assert.equal 0, m\indent_for(lines[2], indent_level, editor)

    for desc in pairs non_indents
      context 'returns the current indent for a line after ' .. desc, ->
        for code in *non_indents[desc]
          it "e.g. does not indent for '#{code}'", ->
            buffer.text = "  #{code}\n  "
            cursor.line = 2
            assert.equal 2, m\indent_for(lines[2], indent_level, editor)

    it 'returns a corrected indent for lines that are on incorrect indentation', ->
      buffer.text = '  bar\n one_column_offset'
      assert.equal 2, m\indent_for(lines[2], indent_level, editor)

    it 'returns the indent for the previous line for a line with a non-motivated indent', ->
      buffer.text = 'bar\n  foo'
      assert.equal 0, m\indent_for(lines[2], indent_level, editor)

    it 'returns the indent for the previous line for a blank line', ->
      buffer.text = '  bar\n'
      assert.equal 2, m\indent_for(lines[2], indent_level, editor)

  describe '.after_newline()', ->
    buffer = Buffer m
    editor = Editor buffer
    cursor = editor.cursor
    lines = buffer.lines
    config.set 'indent', 2, buffer

    context 'splitting brackets', ->
      it 'moves the closing bracket to its own line and positions the cursor at the middle line', ->
        buffer.text = '{\n  }'
        cursor.line = 2
        m\after_newline(lines[2], editor)
        assert.equal buffer.text, '{\n  \n}'
        assert.equal 2, cursor.line
        assert.equal 3, cursor.column

    it 'does nothing for other statements', ->
      for code in *{
        '',
        'foo = bar'
        'foo = bar()'
        'frob\\gurlg!'
      }
        orig_text = code .. '\n'
        buffer.text = orig_text
        cursor.line = 2
        m\after_newline(lines[2], editor)
        assert.equal buffer.text, orig_text
