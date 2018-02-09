append = table.insert

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

  it '.is_empty is true for the empty string', ->
    assert.is_true ('').is_empty
    assert.is_false (' ').is_empty

  it '.is_blank is true for a string that is empty or only contains whitespace', ->
    assert.is_true ('\t\r\n').is_blank
    assert.is_false ('x').is_blank

  it '.stripped contains the string without leading or trailing whitespace', ->
    assert.equal 'foo', ('  \tfoo').stripped
    assert.equal 'foo', ('foo ').stripped
    assert.equal 'foo', ('  \tfoo ').stripped
    assert.equal '', ('  \t').stripped
    assert.equal '', ('').stripped

  it 'ucompare(s1, s2) returns negative, 0 or positive if s1 is smaller, equal or greater than s2', ->
    assert.is_true 'a'\ucompare('b') < 0
    assert.is_true 'a'\ucompare('ä') < 0
    assert.equal 0, 'a'\ucompare('a')
    assert.is_true 'ö'\ucompare('ä') > 0

  it 'is_valid_utf8(s) return true for valid utf8 strings only', ->
    assert.is_true ('abc\194\128').is_valid_utf8
    assert.is_true ('\127').is_valid_utf8
    assert.is_false ('\128').is_valid_utf8
    assert.is_false ('abc\194').is_valid_utf8

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

  describe 'ugmatch(pattern)', ->
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

    it 'returns empty match at init for empty string', ->
      assert.same { 2, 1 }, { 'abc'\ufind '', 2 }

    it 'converts position matches correctly', ->
      assert.same { 1, 3, 1, 4 }, { 'åäö'\ufind '()%S+()' }


  describe 'rfind(pattern [, init])', ->
    it 'searches backward from end using byte offsets', ->
      assert.same { 5, 6 }, { 'äöxx'\rfind 'xx' }

    it 'searches backward from init, when provided', ->
      assert.same { 5, 5 }, { 'äöxxx'\rfind 'x', 5 }

  describe 'urfind(text [, init])', ->
    it 'searches backwards from end using char offsets', ->
      assert.same { 4, 5 }, { 'äöxäöx'\urfind 'äö' }
      assert.same { 3, 6 }, { 'äöxböx'\urfind 'xböx' }
      assert.same { 1, 3 }, { 'äöxböx'\urfind 'äöx' }

    it 'returns nothing for no matches', ->
      assert.same {}, { 'hello'\urfind 'x' }

    it 'searches backwards from init, when provided', ->
      assert.same { 1, 2 }, { 'äöxäöx'\urfind 'äö', 4 }
      assert.same { 1, 2 }, { 'äöxäöx'\urfind 'äö', -3 }
      assert.same { 4, 5 }, { 'äöxäöx'\urfind 'äö', 5 }
      assert.same { 4, 5 }, { 'äöxäöx'\urfind 'äö', -2 }

    it 'matches text entirely before init', ->
      assert.same {1, 2}, { 'abcabc'\urfind 'ab', 4 }

    it 'returns empty match before init for empty string', ->
      assert.same { 2, 1 }, { 'abc'\urfind '', 2 }

  it 'starts_with(s) returns true if the string starts with the specified string', ->
    assert.is_true 'foobar'\starts_with 'foo'
    assert.is_true 'foobar'\starts_with 'foobar'
    assert.is_false 'foobar'\starts_with 'foobarx'
    assert.is_false 'foobar'\starts_with '.oo'

  it 'ends_with(s) returns true if the string ends with the specified string', ->
    assert.is_true 'foobar'\ends_with 'bar'
    assert.is_true 'foobar'\ends_with 'foobar'
    assert.is_false 'foobar'\ends_with 'barx'
    assert.is_false 'foobar'\ends_with '.ar'

  it 'contains(s) returns true if the string contains the specified string', ->
    assert.is_true 'foobar'\contains 'foobar'
    assert.is_true 'foobar'\contains 'bar'
    assert.is_true 'foobar'\contains 'foo'
    assert.is_true 'foobar'\contains 'oba'
    assert.is_false 'foobar'\contains 'arx'
    assert.is_false 'foobar'\contains 'xfo'
    assert.is_false 'foobar'\contains '.'

  describe 'count(s, pattern = false)', ->
    it 'returns the number of occurences of s within the string', ->
      assert.equal 1, 'foobar'\count 'foo'
      assert.equal 2, 'foobar'\count 'o'
      assert.equal 0, 'foobar'\count 'x'

    it 's is evaluated as a pattern if <pattern> is true', ->
      assert.equal 3, 'foo'\count('%w', true)
      assert.equal 2, 'foobar'\count(r'[ab]', true)

    it 's is evaluated as a pattern if it is a regex, regardless of <pattern>', ->
      assert.equal 2, 'foobar'\count(r'[ab]')

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

  describe 'split(pattern)', ->
    it 'splits the string by <pattern>', ->
      assert.same { '1' }, ('1')\split(',')
      assert.same { '1', '2', '3' }, ('1,2,3')\split(',')
      assert.same { '1', '2', '' }, ('1,2,')\split(',')
      assert.same { '', '' }, (',')\split(',')

    it 'treats <pattern> as a lua pattern', ->
      assert.same { 'x', 'y', 'z' }, ('x.y,z')\split('[.,]')
