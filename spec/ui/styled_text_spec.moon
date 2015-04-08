import StyledText from howl.ui

describe 'StyledText', ->

  it 'has a type of StyledText', ->
    assert.equal 'StyledText', typeof StyledText('foo', {})

  it 'responds to tostring correctly', ->
    assert.equal 'my_text', tostring StyledText('my_text', {})

  it 'responds to the length operator (#)', ->
    assert.equal 7, #StyledText('my_text', {})

  it 'can be concatenated with strings', ->
    st = StyledText('foo', {})
    assert.equal 'foobar', st .. 'bar'
    assert.equal 'barfoo', 'bar' .. st

  it 'can be concatenated with StyledText to produce StyledText', ->
    st1 = StyledText('foö', {1, 'string', 5})
    st2 = StyledText('1234', {1, 'number', 5})
    assert.equal StyledText('foö1234', {1, 'string', 5, 5, 'number', 9}), st1 .. st2

  it 'defers to the string meta table', ->
    st = StyledText('xåäö', {})
    assert.equal 'x', st\sub 1, 1
    assert.equal 'å', st\usub 2, 2
    assert.equal 4, st.ulen

  it 'is equal to other StyledText instances with the same values', ->
    assert.equal StyledText('foo', {}), StyledText('foo', {})
    assert.equal StyledText('foo', {1, 'number', 3}), StyledText('foo', {1, 'number', 3})
    assert.not_equal StyledText('fo1', {1, 'number', 3}), StyledText('foo', {1, 'number', 3})
    assert.not_equal StyledText('foo', {1, 'number', 2}), StyledText('foo', {1, 'number', 3})
