import PropertyObject from vilu.aux.moon

describe 'PropertyObject', ->
  context 'declaring properties', ->
    it 'allows specifing a getter and setter using get and set', ->
      value = 'hello'
      class Test extends PropertyObject
        self\property foo:
          get: => value
          set: (v) => value = v

      o = Test!
      assert_equal o.foo, 'hello'
      o.foo = 'world'
      assert_equal o.foo, 'world'

  context 'accessing properties', ->
    it 'assigning a property with only a getter raises a read-only error', ->
      class Test extends PropertyObject
        self\property foo: get: => 'foo'

      o = Test!
      assert_error -> o.foo = 'bar'
      assert_equal o.foo, 'foo'
