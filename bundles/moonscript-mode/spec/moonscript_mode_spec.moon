import bundle, mode, config, Buffer from lunar
import File from lunar.fs
import Editor from lunar.ui

bundle.load_by_name 'moonscript-mode'

describe 'moonscript-mode', ->
  m = mode.by_name 'moonscript'

  it 'registers a mode', ->
    assert.not_nil m

  it 'handles .moon files', ->
    assert.equal mode.for_file(File 'test.moon'), m

  describe '.indent_for(line, indent_level, editor)', ->
    buffer = Buffer m
    editor = Editor buffer
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
        'while foo',
        'unless bar',
      },
      'block statements': {
        'switch foo!'
        'do'
      }

    }

    non_indents = {
      'closed conditionals': {
        'if foo then bar',
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
        'foo! unless bar',
      }
    }

    for desc in pairs indents
      context 'returns a one level indent for a line after ' .. desc, ->
        for code in *indents[desc]
          it "e.g. '#{code}'", ->
            buffer.text = code .. '\n'
            editor.cursor.line = 2
            assert.equal indent_level, m\indent_for(buffer.lines[2], indent_level, editor)

    it 'disregards empty lines above when determining indent', ->
      for desc in pairs indents
        for code in *indents[desc]
          buffer.text = code .. '\n\n'
          editor.cursor.line = 3
          assert.equal indent_level, m\indent_for(buffer.lines[3], indent_level, editor)

    it 'does not disregard blank lines above when determining indent', ->
      for desc in pairs indents
        for code in *indents[desc]
          buffer.text = code .. '\n  \n'
          editor.cursor.line = 3
          assert.equal 2, m\indent_for(buffer.lines[3], indent_level, editor)

    for desc in pairs non_indents
      it 'returns the same indent for a line after ' .. desc, ->
        for code in *non_indents[desc]
          it "e.g. '#{code}'", ->
            buffer.text = "  #{code}\n"
            editor.cursor.line = 2
            assert.equal 2, m\indent_for(buffer.lines[2], indent_level, editor)

  describe '.after_newline()', ->
    buffer = Buffer m
    editor = Editor buffer
    lines = buffer.lines
    config.set 'indent', 2, buffer

    context 'splitting brackets', ->
      it 'moves the closing bracket to its own line', ->
        buffer.text = '{\n  }'
        editor.cursor.line = 2
        m\after_newline(buffer.lines[2], editor)
        assert.equal buffer.text, '{\n  \n}'

    it 'does nothing for other statements', ->
      for code in *{
        '',
        'foo = bar'
        'foo = bar()'
        'frob\\gurlg!'
      }
        orig_text = code .. '\n'
        buffer.text = orig_text
        editor.cursor.line = 2
        m\after_newline(buffer.lines[2], editor)
        assert.equal buffer.text, orig_text
