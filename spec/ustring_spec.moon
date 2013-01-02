describe 'ustrings', ->
  it 'tostring(ustring) returns an ordinary string', ->
    assert.equal 'string', type tostring u'foo'

  it 'creating an ustring from an ustring returns the same string', ->
    s = u'abc'
    assert.equal s.ptr, u(s).ptr

  it 'ustrings can be compared to ordinary lua strings', ->
    assert.equal 'abc', u'abc'
    assert.equal u'abc', 'abc'
    assert.equal 'abcåäö', u'abcåäö'
    assert.is_not.equal 'abcd', u'abc'
    assert.is_not.equal 'abd', u'abc'

  it 'ustring can be compared to other ustrings', ->
    assert.equal u'abc', u'abc'
    assert.equal u'abcåäö', u'abcåäö'
    assert.is_not.equal u'abcd', u'abc'
    assert.is_not.equal u'abd', u'abc'

  it 'ustrings can be concatenated with ordinary lua strings', ->
    assert.equal 'abcd', u'ab' .. 'cd'
    assert.equal 'abcd', 'ab' .. u'cd'

  it 'ustrings can be concatenated with other ustrings', ->
    assert.equal 'abcd', u'ab' .. u'cd'
    assert.equal 'abcd', u'ab' .. u'cd'

  it 'ustrings can be lexically compared to ordinary lua strings', ->
    assert.is_true 'a' < u'b'
    assert.is_true u'a' < 'b'
    assert.is_true u'c' > 'b'
    assert.is_true 'c' > u'b'

  it 'concatenation always returns a ustring', ->
    assert.equal 'ustring', typeof u'ab' .. 'cd'

  it 'the # operator.returns the number of characters in the string', ->
    assert.equal 3, #u('foo')
    assert.equal 3, #u('åäö')

  it '.size contains the number of bytes in the string', ->
    assert.equal 3, u('foo').size
    assert.equal 6, u('åäö').size

  it 'u.is_instance(v) returns true if <v> is an ustring', ->
    assert.is_true u.is_instance u'foo'
    assert.is_false u.is_instance 'foo'
    assert.is_false u.is_instance {}

  it 'len() returns the number characters in the string', ->
    assert.equal 3, u('foo')\len!
    assert.equal 3, u('åäö')\len!

  it 'lower() returns a lower cased version of the string', ->
    assert.equal 'abcåäö', u('aBCåÄÖ')\lower!

  it 'upper() returns a upper cased version of the string', ->
    assert.equal 'ABCÅÄÖ', u('abcåäö')\upper!

  it 'reverse() returns a reversed version of the string', ->
    assert.equal 'abcåäö', u('öäåcba')\reverse!

  describe 'sub(i, [j])', ->
    s = u'aåäöx'

    it 'operates on characters instead of bytes', ->
      assert.equal 'aåä', s\sub 1, 3
      assert.equal 3, #s\sub(1, 3)

    it 'adjusts the indexes similarily to string.sub', ->
      assert.equal 'äöx', s\sub 3 -- j defaults to -1
      assert.equal 'öx', s\sub -2 -- i counts from back
      assert.equal 'aåäöx', s\sub -7 -- is corrected to 1
      assert.equal 'aåäöx', s\sub 1, 123 -- j is corrected to last character
      assert.equal '', s\sub 3, 2 -- empty string when i < j

  describe 'character access using indexing notation', ->
    it 'single character strings can be accessed using indexing notation', ->
      s = u'aåäöx'
      assert.equal 'a', s[1]
      assert.equal 'ä', s[3]

    it 'accesses using invalid indexes returns an empty string', ->
      s = u'abc'
      assert.equal '', s[0]
      assert.equal '', s[4]

    it 'the index can be negative similarily to sub()', ->
      s = u'aåäöx'
      assert.equal 'ä', s[-3]

  describe 'match(pattern [, init])', ->
    it 'returns ustrings for string captures', ->
      assert.same { u'a', 2 }, { u'ab'\match '(%w)()' }

    it 'init specifies a character offset', ->
      assert.same { u'ö', 4 }, { u'äåö'\match '(%S+)()', 3 }

  it 'gmatch(..) always returns ustrings for string captures', ->
    s = u'foo bar'
    gen = s\gmatch '()(%w+)'
    rets = {}
    while true
      vals = { gen! }
      break if #vals == 0
      append rets, vals

    assert.same { { 1, u'foo' }, { 5, u'bar' } }, rets

  describe 'find(s, pattern [, init [, plain]])', ->
    it 'returns character offsets instead of byte offsets', ->
      assert.same {2, 4, 5}, { u'ä öx'\find '%s.+x()' }

    it 'adjust middle-of-sequence position returns to character start', ->
      assert.same {1, 1}, { u'äöx'\find '%S' }

    it 'always returns ustrings for string captures', ->
      assert.same {1, 1, u'a'}, { u'ab'\find '(a)' }

    it 'init specifies a character offset', ->
      assert.same {3, 3, u'ö'}, { u'äåö'\find '(%S+)', 3 }

  it 'format(formatstring, ...) accepts and returns ustrings', ->
    assert.equal 'ustring', typeof u'%d'\format 2

  it 'rep(n, sep) accepts and returns ustrings', ->
    ret = u'a'\rep 2, u'x'
    assert.equal 'axa', ret
    assert.equal 'ustring', typeof ret

  it 'gsub(pattern, repl [, n]) accepts and returns ustrings', ->
    s, count = u'foo bar'\gsub u'%w+', u'bork'
    assert.equal 'bork bork', s
    assert.equal 2, count
    assert.equal 'ustring', typeof s

  describe 'byte_offset(...)', ->
    it 'returns byte offsets for all character offsets passed as parameters', ->
      assert.same {1, 3, 5}, { u'äåö'\byte_offset 1, 2, 3 }

    it 'accepts non-increasing offsets', ->
      assert.same {1, 1}, { u'ab'\byte_offset 1, 1 }

    it 'raises an error for decreasing offsets', ->
      assert.raises 'Decreasing offset', -> u'äåö'\byte_offset 2, 1

    it 'raises error for out-of-bounds offsets', ->
      assert.raises 'out of bounds', -> u'äåö'\byte_offset 1, 2, 4
      assert.raises 'offset', -> u'äåö'\byte_offset 0
      assert.raises 'offset', -> u'a'\byte_offset -1

    it 'when parameters is a table, it returns a table for all offsets within that table', ->
      assert.same {1, 3, 5}, u'äåö'\byte_offset { 1, 2, 3 }

  describe 'poor man system integration', ->
    it 'lpeg.match accepts ustrings', ->
      assert.is_not_nil lpeg.match lpeg.P'a', u'a'

    it 'io.open accepts ustrings', ->
      with_tmpfile (file) ->
        f = assert io.open u file.path
        f\close!
