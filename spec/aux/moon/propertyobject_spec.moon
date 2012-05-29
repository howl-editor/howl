import PropertyObject from vilu.aux.moon

describe 'PropertyObject', ->
  it 'allows specifying a getter and setter using get and set', ->
    value = 'hello'
    class Test extends PropertyObject
      self\property foo:
        get: => value
        set: (v) => value = v

    o = Test!
    assert_equal o.foo, 'hello'
    o.foo = 'world'
    assert_equal o.foo, 'world'

  it 'assigning a property with only a getter raises a read-only error', ->
    class Test extends PropertyObject
      self\property foo: get: => 'foo'

    o = Test!
    assert_error -> o.foo = 'bar'
    assert_equal o.foo, 'foo'

  expect 'two objects of the same class to have the same metatable', ->
    class Test extends PropertyObject
      self\property foo: get: => 'foo'

    assert_equal getmetatable(Test!), getmetatable(Test!)

  expect 'two objects of different classes to have different metatables', ->
    class Test1 extends PropertyObject
      self\property foo: get: => 'foo'

    class Test2 extends PropertyObject
      self\property foo: get: => 'foo'

    assert_not_equal getmetatable(Test1!), getmetatable(Test2!)
