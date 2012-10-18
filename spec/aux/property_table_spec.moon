import PropertyTable from lunar.aux

describe 'PropertyTable(table)', ->
  it 'returns a table with the properties in the passed table', ->
    pt = PropertyTable foo:
      get: (t) -> t.value
      set: (t, v) -> t.value = v

    assert.is_nil pt.foo
    pt.foo = 'hello'
    assert.equal pt.foo, 'hello'

  it 'non-property key accesses return nil by default', ->
    assert.is_nil PropertyTable({}).foo

  it 'non properties can be accessed in the normal fashion', ->
    pt = PropertyTable {
      foo:
        get: -> 'foo'
      bar: -> 'bar'
      frob: 'frob'
    }

    assert.equal pt.foo, 'foo'
    assert.equal pt.frob, 'frob'
    assert.equal pt.bar!, 'bar'

    pt.frob = 'froz'
    assert.equal pt.frob, 'froz'

  it 'writing to a non-property key sets the value', ->
    t = PropertyTable {}
    t.foo = 'bar'
    assert.equal t.foo, 'bar'

  it 'writing to a read-only property raises an error', ->
    assert.error -> PropertyTable(foo: get: -> 'bar').foo = 'frob'

