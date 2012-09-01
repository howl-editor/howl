import PropertyObject from lunar.aux.moon

describe 'PropertyObject', ->
  it 'allows specifying a getter and setter using get and set', ->
    value = 'hello'
    class Test extends PropertyObject
      @property foo:
        get: => value
        set: (v) => value = v

    o = Test!
    assert_equal o.foo, 'hello'
    o.foo = 'world'
    assert_equal o.foo, 'world'

  it 'assigning a property with only a getter raises a read-only error', ->
    class Test extends PropertyObject
      @property foo: get: => 'foo'

    o = Test!
    assert_raises 'read%-only', -> o.foo = 'bar'
    assert_equal o.foo, 'foo'

  expect 'two objects of the same class to have the same metatable', ->
    class Test extends PropertyObject
      @property foo: get: => 'foo'

    assert_equal getmetatable(Test!), getmetatable(Test!)

  expect 'two objects of different classes to have different metatables', ->
    class Test1 extends PropertyObject
      @property foo: get: => 'foo'

    class Test2 extends PropertyObject
      @property foo: get: => 'foo'

    assert_not_equal getmetatable(Test1!), getmetatable(Test2!)

  it 'meta methods are defined via the @meta function', ->
    class Test extends PropertyObject
      @meta __add: (o1, o2) -> 3 + o2

    assert_equal 5, Test! + 2

  describe 'inheritance', ->
    it 'properties defined in any part of the chain works', ->
      class Parent extends PropertyObject
        new: (foo) =>
          super!
          @_foo = foo

        @property foo:
          get: => @_foo or 'wrong'
          set: (v) => @_foo = v .. @foo

      class SubClass extends Parent
        new: (text) => super text

        @property bar:
          get: => @_bar
          set: (v) => @_bar = v

      parent = Parent 'parent'
      assert_equal parent.foo, 'parent'
      parent.foo = 'hello '
      assert_equal parent.foo, 'hello parent'

      s = SubClass 'editor'
      assert_equal s.foo, 'editor'
      s.foo = 'hello'
      assert_equal s.foo, 'helloeditor'
      s.bar = 'world'
      assert_equal s.bar, 'world'

    it 'overriding methods work', ->
      class Parent extends PropertyObject
        foo: => 'parent'

      class SubClass extends Parent
        foo: => 'sub'

      assert_equal SubClass!\foo!, 'sub'

    it 'write to read-only properties are detected', ->
      class Parent extends PropertyObject
        @property foo: get: => 1

      class SubClass extends Parent
        true

      assert_raises 'read%-only', -> SubClass!.foo = 'bar'

    it 'meta methods defined in any part of the chain works', ->
      class Parent extends PropertyObject
        @meta __add: (o1, o2) -> 3 + o2

      class SubClass extends Parent
        @meta __div: (o1, o2) -> 'div'

      o = SubClass!
      assert_equal 5, o + 2
      assert_equal 'div', o / 2
