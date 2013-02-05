import lpeg_lexer from howl.aux
import P,V, Cp from lpeg

l = lpeg_lexer

describe 'lpeg_lexer', ->
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

  describe '.eol matches and consumes new lines', ->
    assert.is_not_nil l.eol\match '\n'
    assert.is_not_nil l.eol\match '\r'
    assert.equals 2, (l.eol * Cp!)\match '\n'
    assert.equals 3, (l.eol * Cp!)\match '\r\n'

    assert.is_nil l.eol\match 'a'
    assert.is_nil l.eol\match '2'

  describe 'any(list)', ->
    it 'the resulting pattern is an ordered match of any member of list', ->
      p = l.any { 'one', 'two' }
      assert.is_not_nil p\match 'one'
      assert.is_not_nil p\match 'two'
      assert.is_nil p\match 'three'

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

  describe 'scan_to(stop_p [, escape_p])', ->
    it 'matches until the specified pattern or <EOF>', ->
      assert.equals 4, (l.scan_to('x') * Cp!)\match '12x'
      assert.equals 4, (l.scan_to('x') * Cp!)\match '123'

    it 'allows escaping <stop_p> with <escape_p>', ->
      p = l.scan_to('}', '\\') * Cp!
      assert.equals 5, p\match '{\\}}'

  describe 'new(definition)', ->
    it 'accepts a function', ->
      assert.not_has_error -> l.new -> true

  it 'the module can be called directly to create a lexer (same as new())', ->
    assert.not_has_error -> l -> true

  it 'the resulting lexer can be called directly', ->
    lexer = l -> P'x' * Cp!
    assert.same { 2 }, lexer 'x'
