import hash from howl

describe 'hash', ->
  it 'supports assignment and indexing like an ordinary table', ->
    h = hash!
    h[1] = 'one'
    h['one'] = 1
    assert.equal 1, h['one']
    assert.equal 1, h.one
    assert.equal 'one', h[1]

  it 'can be constructed using an existing table', ->
    h = hash { 1, 2, foo: 'bar' }
    assert.equal 1, h[1]
    assert.equal 'bar', h.foo

  it '# gives the length of the array part', ->
    h = hash { 'foo' }
    assert.equal 1, #h

  it 'supports the use of strings and ustrings interchangeably for keys', ->
    h = hash!
    h['foo'] = 'bar'
    h[u'bar'] = 'foo'
    assert.equal 'bar', h[u'foo']
    assert.equal 'foo', h['bar']

  it 'can be operated on by the ordinary table. functions', ->
    h = hash { 3, 1, 2 }
    table.sort h
    assert.same { 1, 2, 3 }, h

    assert.equal '123', table.concat h, ''

    table.insert h, 1, 0
    assert.same { 0, 1, 2, 3 }, h

  it 'allows for iteration using pairs', ->
    h = hash { 'one', 'two' }
    copy = [ { k, v }  for k, v in pairs h ]
    assert.same { {1, 'one'}, {2, 'two'} }, copy

  it 'allows for iteration using ipairs', ->
    h = hash { 'one', 'two' }
    copy = [ { k, v }  for k, v in ipairs h ]
    assert.same { {1, 'one'}, {2, 'two'} }, copy
