describe 'ustrings', ->

  it '.ulen holds the number characters in the string', ->
    assert.equal 3, ('foo').ulen
    assert.equal 3, ('åäö').ulen

  it '.ulower is a lower cased version of the string', ->
    assert.equal 'abcåäö', ('aBCåÄÖ').ulower

  it '.uupper is a upper cased version of the string', ->
    assert.equal 'ABCÅÄÖ', ('abcåäö').uupper

  it '.ureverse is a reversed version of the string', ->
    assert.equal 'abcåäö', ('öäåcba').ureverse

  it '.multibyte is true if the string contains multibyte characters', ->
    assert.is_false ('foo').multibyte
    assert.is_true ('åäö').multibyte

  it '.empty is true for the empty string', ->
    assert.is_true ('').empty
    assert.is_false (' ').empty

  it '.blank is true for a string that is empty or only contains whitespace', ->
    assert.is_true ('\t\r\n').blank
    assert.is_false ('x').blank

  it 'ucompare(s1, s2) returns -1, 0 or 1 if s1 is smaller, equal or greater than s2', ->
    assert.equal -1, 'a'\ucompare 'b'
    assert.equal -1, 'a'\ucompare 'ä'
    assert.equal 1, 'ö'\ucompare 'ä'

  describe 'usub(i, [j])', ->
    s = 'aåäöx'

    it 'operates on characters instead of bytes', ->
      assert.equal 'aåä', s\usub 1, 3
      assert.equal 'aåä', s\usub(1, 3)

    it 'adjusts the indexes similarily to string.sub', ->
      assert.equal 'äöx', s\usub 3 -- j defaults to -1
      assert.equal 'öx', s\usub -2 -- i counts from back
      assert.equal 'aåäöx', s\usub -7 -- is corrected to 1
      assert.equal 'aåäöx', s\usub 1, 123 -- j is corrected to last character
      assert.equal '', s\usub 3, 2 -- empty string when i < j

  describe 'character access using indexing notation', ->
    it 'single character strings can be accessed using indexing notation', ->
      s = 'aåäöx'
      assert.equal 'a', s[1]
      assert.equal 'ä', s[3]

    it 'accesses using invalid indexes returns an empty string', ->
      s = 'abc'
      assert.equal '', s[0]
      assert.equal '', s[4]

    it 'the index can be negative similarily to sub()', ->
      s = 'aåäöx'
      assert.equal 'ä', s[-3]

  describe 'umatch(pattern [, init])', ->
    it 'init specifies a character offset', ->
      assert.same { 'ö', 4 }, { 'äåö'\umatch '(%S+)()', 3 }

    it 'if init is greater than the length nil is returned', ->
      assert.is_nil '1'\umatch '1', 2

    it 'accepts regex patterns', ->
      assert.same {'ö'}, { '/ö'\umatch r'\\p{L}'}

  describe 'ugmatch()', ->
    it 'returns character offsets instead of byte offsets', ->
      s = 'föo bãr'
      gen = s\ugmatch '(%S+)()'
      rets = {}
      while true
        vals = { gen! }
        break if #vals == 0
        append rets, vals

      assert.same { { 'föo', 4 }, { 'bãr', 8 } }, rets

    it 'accepts regex patterns', ->
      s = 'well hello there'
      matches = [m for m in s\ugmatch r'\\w+']
      assert.same { 'well', 'hello', 'there' }, matches

  describe 'ufind(pattern [, init [, plain]])', ->
    it 'returns character offsets instead of byte offsets', ->
      assert.same { 2, 4, 5 }, { 'ä öx'\ufind '%s.+x()' }

    it 'adjust middle-of-sequence position returns to character start', ->
      assert.same { 1, 1 }, { 'äöx'\ufind '%S' }

    it 'init specifies a character offset', ->
      assert.same { 3, 3, 'ö' }, { 'äåö'\ufind '(%S+)', 3 }

    it 'if init is greater than the length nil is returned', ->
      assert.is_nil '1'\ufind '1', 2

    it 'accepts regexes', ->
      assert.same { 2, 2 }, { '!ä öx'\ufind r'\\pL' }

  describe 'byte_offset(...)', ->
    it 'returns byte offsets for all character offsets passed as parameters', ->
      assert.same {1, 3, 5, 7}, { 'äåö'\byte_offset 1, 2, 3, 4 }

    it 'accepts non-increasing offsets', ->
      assert.same {1, 1}, { 'ab'\byte_offset 1, 1 }

    it 'raises an error for decreasing offsets', ->
      assert.raises 'Decreasing offset', -> 'äåö'\byte_offset 2, 1

    it 'raises error for out-of-bounds offsets', ->
      assert.raises 'out of bounds', -> 'äåö'\byte_offset 5
      assert.raises 'offset', -> 'äåö'\byte_offset 0
      assert.raises 'offset', -> 'a'\byte_offset -1

    it 'when parameters is a table, it returns a table for all offsets within that table', ->
      assert.same {1, 3, 5}, 'äåö'\byte_offset { 1, 2, 3 }

  describe 'char_offset(...)', ->
    it 'returns character offsets for all byte offsets passed as parameters', ->
      assert.same {1, 2, 3, 4}, { 'äåö'\char_offset 1, 3, 5, 7 }

    it 'accepts non-increasing offsets', ->
      assert.same {2, 2}, { 'ab'\char_offset 2, 2 }

    it 'raises an error for decreasing offsets', ->
      assert.raises 'Decreasing offset', -> 'äåö'\char_offset 3, 1

    it 'raises error for out-of-bounds offsets', ->
      assert.raises 'out of bounds', -> 'ab'\char_offset 4
      assert.raises 'offset', -> 'äåö'\char_offset 0
      assert.raises 'offset', -> 'a'\char_offset -1

    it 'when parameters is a table, it returns a table for all offsets within that table', ->
      assert.same {1, 2, 3, 4}, 'äåö'\char_offset { 1, 3, 5, 7 }
