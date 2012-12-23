u = require 'howl.ustring'

describe 'ustrings', ->
  it 'tostring(ustring) returns an ordinary string', ->
    assert.equal 'string', type tostring u'foo'

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

  it 'the # operator.returns the number of bytes in the string', ->
    assert.equal 3, #u('foo')
    assert.equal 6, #u('åäö')

  it '.ulen contains the number of characters in the string', ->
    assert.equal 3, u('foo').ulen
    assert.equal 3, u('åäö').ulen

  it 'lower() returns a lower cased version of the string', ->
    assert.equal 'abcåäö', u('aBCåÄÖ')\lower!

  it 'upper() returns a upper cased version of the string', ->
    assert.equal 'ABCÅÄÖ', u('abcåäö')\upper!

  it 'reverse() returns a reversed version of the string', ->
    assert.equal 'abcåäö', u('öäåcba')\reverse!
