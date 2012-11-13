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

  describe '.after_newline()', ->
    buffer = Buffer m
    editor = Editor buffer
    lines = buffer.lines
    config.set 'indent', 2, buffer

    indents = {
      'pending function definitions': {
        'foo: =>',
        'foo: -> '
      }
      'pending class declarations': {
        'class Frob',
        'class Frob  ',
      }
      'hanging assignments': {
        'var = ',
        'var: ',
      }
      'open table definitions': {
        'var = { ',
        'var = {',
      },
      'open conditionals': {
        'if foo and bar',
        'unless bar',
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
    }

    for desc in pairs indents
      it 'indents after ' .. desc, ->
        for code in *indents[desc]
          buffer.text = code .. '\n'
          editor.cursor.line = 2
          m\after_newline(buffer.lines[2], editor)
          assert.equal 2, buffer.lines[2].indentation

    for desc in pairs non_indents
      it 'does not indent after ' .. desc, ->
        for code in *non_indents[desc]
          buffer.text = code .. '\n'
          editor.cursor.line = 2
          m\after_newline(buffer.lines[2], editor)
          assert.equal 0, buffer.lines[2].indentation

    context 'when splitting brackets', ->
      it 'moves the closing bracket to its own line', ->
        buffer.text = '{\n}'
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
