import lpeg_lexer from howl.aux
import mode from howl
import P,V, C, Cp, Cg, Cb from lpeg

l = lpeg_lexer

describe 'lpeg_lexer', ->

  describe 'new(definition)', ->
    it 'accepts a function', ->
      assert.not_has_error -> l.new -> true

  it 'the module can be called directly to create a lexer (same as new())', ->
    assert.not_has_error -> l -> true

  it 'the resulting lexer can be called directly', ->
    lexer = l -> P'x' * Cp!
    assert.same { 2 }, lexer 'x'

  it 'imports lpeg definitions locally into the module', ->
    for op in *{'Cp', 'Ct', 'S', 'P'}
      assert.is_not_nil l[op]

  it 'imports lpeg.locale definitions locally into the module', ->
    for ldef in *{'digit', 'upper', 'print', 'lower'}
      assert.is_not_nil l[ldef]

  describe 'capture(style, pattern)', ->
    it 'returns a LPeg pattern', ->
      assert.equal 'pattern', lpeg.type l.capture('foo', P(1))

    it 'the returned pattern produces the three captures <start-pos>, <style-name> and <end-pos> if <pattern> matches', ->
      p = l.capture 'foo', P'fo'
      assert.same { 1, 'foo', 3 }, { p\match 'foobar' }

  describe 'predefined helper patterns', ->
    describe '.eol', ->
      it 'matches and consumes new lines', ->
        assert.is_not_nil l.eol\match '\n'
        assert.is_not_nil l.eol\match '\r'
        assert.equals 2, (l.eol * Cp!)\match '\n'
        assert.equals 3, (l.eol * Cp!)\match '\r\n'

        assert.is_nil l.eol\match 'a'
        assert.is_nil l.eol\match '2'

    describe '.float', ->
      it 'matches and consumes various float representations', ->
        for repr in *{ '34.5', '3.45e2', '1.234E1', '3.45e-2', '.32' }
          assert.is_not_nil l.float\match repr

    describe '.hexadecimal', ->
      it 'matches and consumes various hexadecimal representations', ->
        for repr in *{ '0xfeab', '0XDEADBEEF' }
          assert.is_not_nil l.hexadecimal\match repr

      it 'does not match illegal hexadecimal representations', ->
        assert.is_nil l.hexadecimal\match '0xCDEFG'

    describe '.hexadecimal_float', ->
      it 'matches and consumes various hexadecimal float representations', ->
        for repr in *{ '0xfep2', '0XAP-3' }
          assert.is_not_nil l.hexadecimal_float\match repr

      it 'does not match illegal hexadecimal representations', ->
        assert.is_nil l.hexadecimal_float\match '0xFGp3'

    describe '.octal', ->
      it 'matches and consumes octal representations', ->
        assert.is_not_nil l.octal\match '0123'

      it 'does not match illegal octal representations', ->
        assert.is_nil l.octal\match '0128'

    describe '.line_start', ->
      it 'matches after newline or at start of text', ->
        assert.is_not_nil l.line_start\match 'x'
        assert.is_not_nil (l.eol * l.line_start * P'x')\match '\nx'

      it 'does not consume anything', ->
        assert.equals 2, (l.eol * l.line_start * Cp!)\match '\nx'

  describe 'any(list)', ->
    it 'the resulting pattern is an ordered match of any member of <list>', ->
      p = l.any { 'one', 'two' }
      assert.is_not_nil p\match 'one'
      assert.is_not_nil p\match 'two'
      assert.is_nil p\match 'three'

    it '<list> can be vararg arguments', ->
      p = l.any 'one', 'two'
      assert.is_not_nil p\match 'two'

  describe 'sequence(list)', ->
    it 'the resulting pattern is a chained match of all members of <list>', ->
      p = l.sequence { 'one', 'two' }
      assert.is_nil p\match 'one'
      assert.is_nil p\match 'two'
      assert.is_not_nil p\match 'onetwo'
      assert.is_nil p\match 'Xonetwo'

    it '<list> can be vararg arguments', ->
      p = l.sequence 'one', 'two'
      assert.is_not_nil p\match 'onetwo'

  describe 'word(list)', ->
    grammar = P {
      V'word' + P(1) * V(1)
      word: l.word { 'one', 'two' }
    }

    it 'returns a pattern who matches any word in <list>', ->
      assert.is_not_nil grammar\match 'one'
      assert.is_not_nil grammar\match 'so one match'
      assert.is_not_nil grammar\match '!one'
      assert.is_not_nil grammar\match 'one()'
      assert.is_not_nil grammar\match 'then two'
      assert.is_nil grammar\match 'three'

    it 'only matches standalone words, not substring occurences', ->
      assert.is_nil grammar\match 'fone'
      assert.is_nil grammar\match 'twofold'
      assert.is_nil grammar\match 'two_fold'

    it 'accepts var arg parameters', ->
      assert.is_not_nil l.word('one', 'two')\match 'two'

  describe 'span(start_p, stop_p [, escape_p])', ->
    p = l.span('{', '}') * Cp!

    it 'matches and consumes from <start_p> up to and including <stop_p>', ->
      assert.equals 3, p\match '{}'
      assert.equals 5, p\match '{xx}'

    it 'always considers <EOF> as an alternate stop marker', ->
      assert.equals 3, p\match '{x'

    it 'allows escaping <stop_p> with <escape_p>', ->
      p = l.span('{', '}', '\\') * Cp!
      assert.equals 5, p\match '{\\}}'

  describe 'paired(p, escape [, pair_style, content_style])', ->
    p = l.paired(1) * Cp!

    it 'matches and consumes from <p> up to and including the matching <p>', ->
      assert.equals 3, p\match '||x'
      assert.equals 5, p\match '|xx|x'

    it 'always considers <EOF> as an alternate stop marker', ->
      assert.equals 3, p\match '|x'

    it 'allows escaping the end delimiter with <escape>', ->
      p = l.paired(1, '\\') * Cp!
      assert.equals 5, p\match '|\\|| foo\\'

    context 'when pair_style and content_style are specified', ->
      it 'captures the components in the specified styles', ->
        p = l.paired(1, nil, 'keyword', 'string')
        expected = {
          1, 'keyword', 2,
          2, 'string', 5,
          5, 'keyword', 6,
        }
        assert.same expected, { p\match '|foo|' }

      it 'still handles escapes properly', ->
        p = l.paired(1, '%', 'keyword', 'string')
        expected = {
          1, 'keyword', 2,
          2, 'string', 6,
          6, 'keyword', 7,
        }
        assert.same expected, { p\match '|f%|o|' }

  describe 'back_was(name, value)', ->
    p = Cg(l.alpha^1, 'group') * ' ' * l.back_was('group', 'foo')

    it 'matches if the named capture <named> previously matched <value>', ->
      assert.is_not_nil p\match 'foo '

    it 'does not match if the named capture <named> did not match <value>', ->
      assert.is_nil p\match 'bar '

    it 'produces no captures', ->
      assert.equals 1, #{ p\match 'foo ' }

  describe 'match_back(name)', ->
    p = Cg(P'x', 'start') * 'y' * l.match_back('start')

    it 'matches the named capture given by <name>', ->
      assert.equals 4, p\match 'xyxzx'

    it 'produces no captures', ->
      assert.equals 1, #{ p\match 'xyxzx' }

  describe 'scan_until(stop_p [, escape_p])', ->
    it 'matches until the specified pattern or <EOF>', ->
      assert.equals 3, (l.scan_until('x') * Cp!)\match '12x'
      assert.equals 4, (l.scan_until('x') * Cp!)\match '123'

    it 'allows escaping <stop_p> with <escape_p>', ->
      p = l.scan_until('}', '\\') * Cp!
      assert.equals 4, p\match '{\\}}'

  describe 'scan_to(stop_p [, escape_p])', ->
    it 'matches until the specified pattern or <EOF>', ->
      assert.equals 4, (l.scan_to('x') * Cp!)\match '12x'
      assert.equals 4, (l.scan_to('x') * Cp!)\match '123'

    it 'allows escaping <stop_p> with <escape_p>', ->
      p = l.scan_to('}', '\\') * Cp!
      assert.equals 5, p\match '{\\}}'

  describe 'scan_through_indented', ->
    p = P' ' * l.scan_through_indented! * Cp!

    it 'matches until the indentation is smaller or equal to the current line', ->
      assert.equals 4, p\match ' x\n y'
      assert.equals 8, p\match ' x\n  y\n z'

    it 'matches until eol if it can not find any line with smaller or equal indentation', ->
      assert.equals 7, p\match ' x\n  y'

    it 'uses the indentation of the line containing eol if positioned right at it', ->
      p = l.eol * l.scan_through_indented! * Cp!
      assert.equals 8, p\match ' x\n  y\n z', 3

  describe 'scan_until_capture(name, escape, [, halt_at, halt_at_N, ..])', ->

    it 'matches until the named capture', ->
      p = Cg('x', 'start') * l.scan_until_capture('start')
      assert.equals 4, p\match 'xyzx'

    it 'stops matching at any optional halt_at parameters', ->
      p = Cg('x', 'start') * l.scan_until_capture('start', nil, 'z')
      assert.equals 3, p\match 'xyzx'

    it 'treats all stop parameters as strings and not patterns', ->
      p = Cg('x', 'start') * l.scan_until_capture('start', nil, '%w')
      assert.equals 4, p\match 'xyz%w'

    it 'does not halt on escaped matches', ->
      p = Cg('x', 'start') * l.scan_until_capture('start', '\\', 'z')
      assert.equals 7, p\match 'xy\\x\\zx'

    it 'matches until eof if no match is found', ->
      p = Cg('x', 'start') * l.scan_until_capture('start')
      assert.equals 4, p\match 'xyz'

  describe 'match_until(stop_p, p)', ->
    p = l.match_until('\n', C(l.alpha)) * Cp!

    it 'matches p until stop_p matches', ->
      assert.same { 'x', 'y', 'z', 4 }, { p\match 'xyz\nx' }

    it 'matches until eof if stop_p is not found', ->
      assert.same { 'x', 'y', 3 }, { p\match 'xy' }

  describe 'complement(p)', ->
    it 'matches if <p> does not match', ->
      assert.is_not_nil l.complement('a')\match 'b'
      assert.is_nil l.complement('a')\match 'a'
      assert.equals 3, (l.complement('a')^1 * Cp!)\match 'bca'

  describe 'sub_lex_by_pattern(mode_p, mode_style, stop_p)', ->
    context 'when no mode is found for the <mode_p> capture', ->
      it 'emits mode match styling and an embedded capture for the sub text', ->
        p = l.sub_lex_by_pattern(l.alpha^1, 'keyword', '>')
        res = { p\match 'xx123>' }
        assert.same {
          1, 'embedded:keyword', 3,
          3, 'embedded', 6
        }, res

    context 'when a mode matching the <mode_p> capture exists', ->
      local p

      before_each ->
        sub_mode = lexer: l -> capture('number', digit^1)
        mode.register name: 'dynsub', create: -> sub_mode
        p = l.P'<' * l.sub_lex_by_pattern(l.alpha^1, 'keyword', '>')

      after_each ->
        mode.unregister 'dynsub'

      it 'emits mode match styling and rebasing instructions to the styler', ->
        assert.same {
          2, 'embedded:keyword', 8,
          8, {}, 'dynsub|embedded'
        }, { p\match '<dynsub>' }

      it "lexes the content using that mode's lexer until <stop_p>", ->
        assert.same {
          2, 'embedded:keyword', 8,
          8, { 1, 'number', 4 }, 'dynsub|embedded'
        }, { p\match '<dynsub123>' }

  describe 'sub_lex(mode_name, stop_p)', ->
    context 'when no mode is found matching <mode_name>', ->
      it 'captures using the embedded style until stop_p', ->
        p = l.sub_lex('unknown', '>')
        res = { p\match 'xx>' }
        assert.same {1, 'embedded', 3}, res

    context 'when a mode matching <mode_name> exists', ->
      local p

      before_each ->
        sub_mode = lexer: l -> capture('number', digit^1)
        mode.register name: 'sub', create: -> sub_mode
        p = l.sub_lex('sub', '>')

      after_each ->
        mode.unregister 'sub'

      sub_captures_for = (text) ->
        res = { p\match text }
        res[2]

      it 'emits rebasing instructions to the styler', ->
        assert.same { 1, {}, 'sub|embedded' }, { p\match '' }

      it "lexes the content using that mode's lexer until <stop_p>", ->
        assert.same {1, 'number', 3}, sub_captures_for '12>'

      it 'lexes until EOF if <stop_p> is not found', ->
        assert.same {1, 'number', 3}, sub_captures_for '12'

  describe 'built-in lexing support', ->
    it 'automatically lexes whitespace', ->
      lexer = l -> P'peace-and-quiet'
      assert.same { 1, 'whitespace', 3 }, lexer ' \n'

    it 'automatically skips non-recognized tokens', ->
      lexer = l -> capture 'foo', P'foo'
      assert.same { 2, 'foo', 5 }, lexer '|foo'
