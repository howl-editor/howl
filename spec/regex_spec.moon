describe 'Regex', ->
  context 'creation', ->
    it 'raises an error if the pattern is invalid', ->
      assert.raises 'regular expression', -> r'?\\'

    it 'returns a regex for a valid pattern', ->
      assert.is_not_nil r'foo()\\d+'

    it 'accepts a regex as well', ->
      assert.is_not_nil r r'foo()\\d+'

  it '.pattern holds the regex used for construction', ->
    assert.equal 'foo(bar)', r('foo(bar)').pattern

  it '.capture_count holds the number of captures in the pattern', ->
    assert.equal 2, r('foo(bar) (\\w+)').capture_count

  it 'r.is_instance(v) returns true if <v> is a regex', ->
    assert.is_true r.is_instance r'foo'
    assert.is_false r.is_instance 'foo'
    assert.is_false r.is_instance {}

  describe 'match(string [, init])', ->
    it 'returns nil if the pattern does not match', ->
      assert.is_nil r'foo'\match 'bar'

    context 'with no captures in the pattern', ->
      it 'returns the entire match', ->
        assert.equal 'right', r'ri\\S+'\match 'red right hand'

    context 'with captures in the pattern', ->
      it 'returns the captured values', ->
        assert.same { u'red', u'right' }, { r'(r\\w+)\\s+(\\S+)'\match 'red right hand' }

      it 'empty captures are returned as position captures', ->
        assert.same { 1, 4 }, { r'()red()'\match 'red' }

      it 'position captures are character based', ->
        assert.same { 2, 3 }, { r'å()ä()'\match 'åäö' }

    context 'when init is specified', ->
      it 'matching starts from the init position', ->
        assert.equal 'right', r'r\\S+'\match 'red right hand', 2

      it 'negative values counts from the end', ->
        assert.equal 'og', r'o\\w'\match 'top dog', -2

    it 'both patterns and subjects can be ustrings', ->
      assert.equal 'right', r(u'ri\\S+')\match u'red right hand'

    it 'returned string captures are always ustrings', ->
      capture = r'\\S+'\match 'åäö'
      assert.equal 3, #capture

  it 'escape(s) returns a string with all special regular expression symbols escaped', ->
    assert.equal 'a\\.b\\*c', r.escape 'a.b*c'

  it 'tostring(regex) returns the pattern', ->
    assert.equal '\\s*(foo)', tostring r'\\s*(foo)'