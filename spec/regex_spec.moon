describe 'Regex', ->
  context 'creation', ->
    it 'raises an error if the pattern is invalid', ->
      assert.raises 'regular expression', -> r'?\\'

    it 'returns a regex for a valid pattern', ->
      assert.is_not_nil r'foo()\\d+'

    it 'accepts a regex as well', ->
      assert.is_not_nil r r'foo()\\d+'

    it 'accepts and optional table of compile flags', ->
      reg = r '.', {r.DOTALL}
      assert.is_truthy reg\match "\n"

    it 'accepts and optional table of match flags', ->
      reg = r 'x', nil, {r.MATCH_ANCHORED}
      assert.is_falsy reg\match "ax"

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
        assert.same { 'red', 'right' }, { r'(r\\w+)\\s+(\\S+)'\match 'red right hand' }

      it 'empty captures are returned as position captures', ->
        assert.same { 1, 4 }, { r'()red()'\match 'red' }

      it 'position captures are character based', ->
        assert.same { 2, 3 }, { r'å()ä()'\match 'åäö' }

      it 'return non-matching optional captures as empty strings', ->
        assert.same { '1', '', '2' }, { r'(1)(\\w)?(2)'\match '12' }

    context 'when init is specified', ->
      it 'matching starts from the init position', ->
        assert.equal 'right', r'r\\S+'\match 'red right hand', 2
        assert.equal 6, r'r()\\S+'\match 'red right hand', 2

      it 'negative values counts from the end', ->
        assert.equal 'og', r'o\\w'\match 'top dog', -2

  describe 'find(s, init)', ->
    it 'returns nil if the pattern could not be found in <s>', ->
      assert.is_nil r'foo'\find 'bar'

    it 'returns the indices where the pattern match starts and end if found', ->
      assert.same { 2, 2 }, { r'\\pL'\find '!äö' }

    it 'returns any captures after the indices', ->
      assert.same { 2, 2, 'ä' }, { r'(\\pL)'\find '!äö' }

    it 'empty captures are returned as position captures', ->
      assert.same { 2, 2, 3 }, { r'\\pL()'\find '!äö' }

    it 'starts matching after init', ->
      assert.same { 3, 5, 6 }, { r'\\w+()'\find '12ab2', 3}

  describe 'gmatch(s)', ->
    context 'with no captures in the pattern', ->
      it 'produces each consecutive match in each call', ->
        matches = [m for m in r'\\w+'\gmatch 'well hello there']
        assert.same { 'well', 'hello', 'there' }, matches

    context 'with captures in the pattern', ->
      it 'returns empty captures as position matches', ->
        matches = [p for p in r'()\\pL+'\gmatch 'well hellö there' ]
        assert.same { 1, 6, 12 }, matches

      it 'produces the the set of captures in each call', ->
        matches = [{p,m} for p,m in r'()(\\w+)'\gmatch 'well hello there']
        assert.same { {1, 'well'}, {6, 'hello'}, {12, 'there'} }, matches

    it 'returns no matches when it does not match', ->
      matches = [m for m in r'\\d+'\gmatch 'well hello there']
      assert.same {}, matches

  describe 'test(s)', ->
    it 'returns true if the regex matches <s>', ->
      assert.is_true r('ri\\S+')\test 'red right hand'

    it 'returns false if the regex does not match <s>', ->
      assert.is_false r('foo')\test 'bar'

  it 'escape(s) returns a string with all special regular expression symbols escaped', ->
    assert.equal 'a\\.b\\*c', r.escape 'a.b*c'

  it 'tostring(regex) returns the pattern', ->
    assert.equal '\\s*(foo)', tostring r'\\s*(foo)'
