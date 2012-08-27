import PropertyTable from vilu.aux

describe 'PropertyTable(table)', ->
  it 'returns a table with the properties in the passed table', ->
    pt = PropertyTable foo:
      get: (t) -> t.value
      set: (t, v) -> t.value = v

    assert_nil pt.foo
    pt.foo = 'hello'
    assert_equal pt.foo, 'hello'

  it 'non-property key accesses return nil by default', ->
    assert_nil PropertyTable({}).foo

  it 'non properties can be accessed in the normal fashion', ->
    pt = PropertyTable {
      foo:
        get: -> 'foo'
      bar: -> 'bar'
      frob: 'frob'
    }

    assert_equal pt.foo, 'foo'
    assert_equal pt.frob, 'frob'
    assert_equal pt.bar!, 'bar'

    pt.frob = 'froz'
    assert_equal pt.frob, 'froz'

  it 'writing to a non-property key sets the value', ->
    t = PropertyTable {}
    t.foo = 'bar'
    assert_equal t.foo, 'bar'

  it 'writing to a read-only property raises an error', ->
    assert_error -> PropertyTable(foo: get: -> 'bar').foo = 'frob'

