import PropertyObject from howl.util.moon

describe 'PropertyObject', ->
  it 'allows specifying a getter and setter using get and set', ->
    value = 'hello'
    class Test extends PropertyObject
      @property foo:
        get: => value
        set: (v) => value = v

    o = Test!
    assert.equal o.foo, 'hello'
    o.foo = 'world'
    assert.equal o.foo, 'world'

  it 'assigning a property with only a getter raises a read-only error', ->
    class Test extends PropertyObject
      @property foo: get: => 'foo'

    o = Test!
    assert.raises 'read%-only', -> o.foo = 'bar'
    assert.equal o.foo, 'foo'

  it 'two objects of the same class have the same metatable', ->
    class Test extends PropertyObject
      @property foo: get: => 'foo'

    assert.equal getmetatable(Test!), getmetatable(Test!)

  it 'two objects of different classes have different metatables', ->
    class Test1 extends PropertyObject
      @property foo: get: => 'foo'

    class Test2 extends PropertyObject
      @property foo: get: => 'foo'

    assert.is_not.equal getmetatable(Test1!), getmetatable(Test2!)

  it 'meta methods are defined via the @meta function', ->
    class Test extends PropertyObject
      @meta __add: (o1, o2) -> 3 + o2

    assert.equal 5, Test! + 2

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
      assert.equal parent.foo, 'parent'
      parent.foo = 'hello '
      assert.equal parent.foo, 'hello parent'

      s = SubClass 'editor'
      assert.equal s.foo, 'editor'
      s.foo = 'hello'
      assert.equal s.foo, 'helloeditor'
      s.bar = 'world'
      assert.equal s.bar, 'world'

    it 'overriding methods work', ->
      class Parent extends PropertyObject
        foo: => 'parent'

      class SubClass extends Parent
        foo: => 'sub'

      assert.equal SubClass!\foo!, 'sub'

    it 'write to read-only properties are detected', ->
      class Parent extends PropertyObject
        @property foo: get: => 1

      class SubClass extends Parent
        true

      assert.raises 'read%-only', -> SubClass!.foo = 'bar'

    it 'meta methods defined in any part of the chain works', ->
      class Parent extends PropertyObject
        @meta __add: (o1, o2) -> 3 + o2

      class SubClass extends Parent
        @meta __div: (o1, o2) -> 'div'

      o = SubClass!
      assert.equal 5, o + 2
      assert.equal 'div', o / 2

    it 'properties on subclass and base are independent', ->
      class Parent extends PropertyObject
        @property foo:
          get: => 'parent'

      class SubClass extends Parent
        @property foo:
          get: => 'sub'

      assert.equal Parent!.foo, 'parent'
      assert.equal SubClass!.foo, 'sub'

  describe 'delegation', ->
    it 'allows delegating to a default object passed in the constructor', ->
      target = {
        foo: 'bar'
        func: spy.new -> 'return'
      }

      class Delegating extends PropertyObject
        new: => super target
        @property frob: get: => 'nic'

      o = Delegating!
      assert.equals 'nic',  o.frob
      assert.equals 'bar',  o.foo
      assert.equals 'return',  o\func!
      assert.spy(target.func).was.called_with target
