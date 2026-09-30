{:parse} = howl.util.dotenv

describe 'dotenv', ->
  describe 'parse(text, lookup)', ->
    it 'returns the variables assigned on each line', ->
      assert.same { A: '1', B: 'two' }, parse 'A=1\nB=two\n'

    it 'allows whitespace around the "=" and an "export" prefix', ->
      assert.same { A: '1', B: '2', export: '3' }, parse 'A = 1\n  export B=2\nexport=3'

    it 'skips blank lines, comments and lines that do not parse', ->
      assert.same { A: '1', B: '2' }, parse '# comment\n\nA=1\nnot a variable\n  # x=y\nB=2'

    it 'handles "\\r\\n" line endings', ->
      assert.same { A: '1', B: '2' }, parse 'A=1\r\nB=2\r\n'

    context 'for unquoted values', ->
      it 'trims them and strips comments that follow whitespace', ->
        assert.same { A: 'x#y', B: 'value' }, parse 'A=x#y\nB= value  # comment\n'

      it 'gives an empty value when nothing follows the "="', ->
        assert.same { A: '' }, parse 'A='

    context 'for single-quoted values', ->
      it 'takes the text as is, even across lines', ->
        assert.same { A: 'a # \\n ${B}', C: 'x\ny' }, parse "A='a # \\n ${B}' # comment\nC='x\ny'"

    context 'for double-quoted values', ->
      it 'handles escapes and allows the value to span lines', ->
        assert.same { A: 'a\n"b"\t\\c', B: 'x\ny' }, parse 'A="a\\n\\"b\\"\\t\\\\c" # comment\nB="x\ny"'

      it 'keeps unknown escapes', ->
        assert.same { A: '\\d' }, parse 'A="\\d"'

    it 'skips a value with a missing closing quote', ->
      assert.same { B: '2' }, parse 'A="1\nB=2'

    context 'expansion', ->
      lookup = (name) -> ({ HOME: '/home/me', EMPTY: '' })[name]

      it 'expands ${NAME} from earlier variables first, then using lookup', ->
        vars = parse 'HOME=/x\nA=${HOME}/a\nB="${HOME}/b"\nC=${NONE}.', lookup
        assert.same { HOME: '/x', A: '/x/a', B: '/x/b', C: '.' }, vars
        assert.equals '/home/me/a', parse('A=${HOME}/a', lookup).A

      it 'uses the default of ${NAME:-default} for unset or empty variables', ->
        vars = parse 'A=${NONE:-a}\nB=${EMPTY:-b}\nC=${HOME:-c}', lookup
        assert.same { A: 'a', B: 'b', C: '/home/me' }, vars

      it 'leaves other uses of "$" alone', ->
        assert.same { A: 'p$ss$HOME${1x}' }, parse 'A=p$ss$HOME${1x}', lookup
