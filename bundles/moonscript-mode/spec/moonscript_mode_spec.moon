import bundle, mode, config, Buffer from lunar
import File from lunar.fs
import Editor from lunar.ui

bundle.load_by_name 'moonscript-mode'

describe 'moonscript-mode', ->
  m = mode.by_name 'moonscript'

  it 'registers a mode', ->
    assert_not_nil m

  it 'handles .moon files', ->
    assert_equal mode.for_file(File 'test.moon'), m

  describe '.after_newline()', ->
    buffer = Buffer m
    editor = Editor buffer
    config.set 'indent', 2, buffer

    indents = {
      ['pending function definitions']: {
        'foo: =>',
        'foo: -> '
      }
      ['pending class declarations']: {
        'class Frob',
        'class Frob  ',
      }
      ['hanging assignments']: {
        'var = ',
        'var: ',
      }
      ['open table definitions']: {
        'var = { ',
        'var = {',
      }
    }

    for desc in pairs indents
      it 'indents after ' .. desc, ->
        for code in *indents[desc]
          buffer.text = code .. '\n'
          editor.cursor.line = 2
          m\after_newline(buffer.lines[2], editor)
          assert_equal buffer.lines[2].text, '  '

    context 'when splitting brackets', ->
      it 'moves the closing bracket to its own line', ->
        buffer.text = '{\n}'
        editor.cursor.line = 2
        m\after_newline(buffer.lines[2], editor)
        assert_equal buffer.text, '{\n  \n}'

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
        assert_equal buffer.text, orig_text
