-- Real code in Howlscript: the PropertyObject spec (spec/util/moon/
-- propertyobject_spec.moon), with its classes in Howlscript, run against a
-- Howlscript port of PropertyObject.

howlscript = require 'howlscript'
match = require 'luassert.match'
{:run} = require 'howlscript.spec.support'

describe 'acceptance: PropertyObject in Howlscript', ->
  PropertyObject = nil

  setup ->
    fixture = debug.getinfo(1, 'S').source\match('^@(.+/)') .. 'fixtures/property_object.howl'
    PropertyObject = assert(howlscript.loadfile fixture)!

  classes = (src, env = {}) ->
    env.PropertyObject = PropertyObject
    run src, env

  it 'allows specifying a getter and setter using get and set', ->
    Test = classes [[
      value = 'hello'
      class Test extends PropertyObject
        @property(foo: {
          get: => value
          set: (v) => value = v
        })
    ]]
    o = Test!
    assert.equal o.foo, 'hello'
    o.foo = 'world'
    assert.equal o.foo, 'world'

  it 'assigning a property with only a getter raises a read-only error', ->
    Test = classes [[
      class Test extends PropertyObject
        @property(foo: {get: => 'foo'})
    ]]
    o = Test!
    assert.raises 'read%-only', -> o.foo = 'bar'
    assert.equal o.foo, 'foo'

  it 'gives objects of the same class the same metatable, and of others different ones', ->
    Test1, Test2 = classes [[
      class Test1 extends PropertyObject
        @property(foo: {get: => 'foo'})
      class Test2 extends PropertyObject
        @property(foo: {get: => 'foo'})
      Test1, Test2
    ]]
    assert.equal getmetatable(Test1!), getmetatable(Test1!)
    assert.is_not.equal getmetatable(Test1!), getmetatable(Test2!)

  it 'defines meta methods via the @meta function', ->
    Test = classes [[
      class Test extends PropertyObject
        @meta(__add: (o1, o2) -> 3 + o2)
    ]]
    assert.equal 5, Test! + 2

  describe 'inheritance', ->
    it 'handles properties defined in any part of the chain', ->
      Parent, SubClass = classes [[
        class Parent extends PropertyObject
          new: (foo) =>
            super()
            @_foo = foo

          @property(foo: {
            get: => @_foo or 'wrong'
            set: (v) => @_foo = v .. @foo
          })

        class SubClass extends Parent
          new: (text) => super(text)

          @property(bar: {
            get: => @_bar
            set: (v) => @_bar = v
          })
        Parent, SubClass
      ]]

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

    it 'lets methods be overridden', ->
      SubClass = classes [[
        class Parent extends PropertyObject
          foo: => 'parent'

        class SubClass extends Parent
          foo: => 'sub'
      ]]
      assert.equal SubClass!\foo!, 'sub'

    it 'leaves the parent, and its siblings, alone when overriding a property', ->
      Parent, SubClass, Sibling = classes [[
        class Parent extends PropertyObject
          @property(foo: {get: => 'parent'})

        class SubClass extends Parent
          @property(foo: {get: => 'sub'})

        class Sibling extends Parent
        Parent, SubClass, Sibling
      ]]
      assert.equal 'parent', Parent!.foo
      assert.equal 'sub', SubClass!.foo
      assert.equal 'parent', Sibling!.foo

    it 'leaves the parent alone when overriding a meta method', ->
      Parent, SubClass = classes [[
        class Parent extends PropertyObject
          @meta(__tostring: => 'parent')

        class SubClass extends Parent
          @meta(__tostring: => 'sub')
        Parent, SubClass
      ]]
      assert.equal 'parent', tostring Parent!
      assert.equal 'sub', tostring SubClass!

    it 'detects writes to inherited read-only properties', ->
      SubClass = classes [[
        class Parent extends PropertyObject
          @property(foo: {get: => 1})

        class SubClass extends Parent
      ]]
      assert.raises 'read%-only', -> SubClass!.foo = 'bar'

    it 'handles meta methods defined in any part of the chain', ->
      SubClass = classes [[
        class Parent extends PropertyObject
          @meta(__add: (o1, o2) -> 3 + o2)

        class SubClass extends Parent
          @meta(__div: (o1, o2) -> 'div')
      ]]
      o = SubClass!
      assert.equal 5, o + 2
      assert.equal 'div', o / 2

  describe 'delegation', ->
    it 'delegates to a default object passed in the constructor', ->
      target = {
        foo: 'bar'
        func: spy.new -> 'return'
      }
      Delegating = classes [[
        class Delegating extends PropertyObject
          new: => super(target)
          @property(frob: {get: => 'nic'})
      ]], :target

      o = Delegating!
      assert.equals 'nic',  o.frob
      assert.equals 'bar',  o.foo
      assert.equals 'return',  o\func!
      assert.spy(target.func).was.called_with match.is_ref(target)
