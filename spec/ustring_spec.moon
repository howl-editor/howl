u = require 'howl.ustring'

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
    us = u'ab'
    result = us .. 'cd'
    assert.equal getmetatable(us), getmetatable(result)

  it 'the # operator.returns the number of characters in the string', ->
    assert.equal 3, #u('foo')
    assert.equal 3, #u('åäö')

  it '.size contains the number of bytes in the string', ->
    assert.equal 3, u('foo').size
    assert.equal 6, u('åäö').size

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

