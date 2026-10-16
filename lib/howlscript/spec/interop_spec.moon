-- Howlscript classes have MoonScript's layout, so the two can extend each other.

moonscript = require 'moonscript'
{:dedent, :run} = require 'howlscript.spec.support'
{:PropertyObject} = howl.util.moon

describe 'interop with MoonScript classes', ->
  moon_run = (src, env = {}) ->
    setmetatable env, __index: _G
    f = assert moonscript.loadstring dedent(src)
    setfenv(f, env)!

  it 'lets a Howlscript class extend a MoonScript one', ->
    Animal = moon_run [[
      class Animal
        new: (@name) =>
        speak: => "#{@name} makes a sound"
        @create: (name) => @ name
    ]]
    assert.same {'Rex barks; Rex makes a sound', 'Dog', true}, {run [[
      class Dog extends Animal
        new: (name) =>
          super(name)
        speak: => "#{@name} barks; " .. super()
      dog = Dog:create('Rex')
      dog:speak(), typeof(dog), dog.__class.__parent == Animal
    ]], :Animal}

  it 'lets a MoonScript class extend a Howlscript one', ->
    Animal = run [[
      class Animal
        new: (@name) =>
        speak: => "#{@name} makes a sound"
    ]]
    Dog = moon_run [[
      class Dog extends Animal
        speak: => "woof, " .. super!
    ]], :Animal
    dog = Dog 'Rex'
    assert.equals 'woof, Rex makes a sound', dog\speak!
    assert.equals 'Dog', typeof dog

  it 'calls __inherited on a MoonScript parent', ->
    Base = moon_run [[
      class Base
        @__inherited: (child) => @child = child.__name
    ]]
    run 'class Sub extends Base', :Base
    assert.equals 'Sub', Base.child

  it "gives a Howlscript subclass the metamethods of a MoonScript parent", ->
    Point = moon_run [[
      class Point
        new: (@x) =>
        __tostring: => "P#{@x}"
    ]]
    assert.equals 'P1', tostring run([[
      class Sub extends Point
      Sub(1)
    ]], :Point)

  describe 'MoonScript subclasses of Howlscript classes with properties', ->
    Base = nil

    before_each ->
      Base = run [[
        class Base
          @__inherited: (child) => @child = child.__name
          new: (@_v = 'v') =>
          property value
            get: => @_v
            set: (v) => @_v = v:upper()
          property size => #@_v
          __tostring: => "Base(#{@_v})"
          __index: (key) => "fallback #{key}"
      ]]

    it 'get the properties, metamethods and fallbacks', ->
      Sub = moon_run [[
        class Sub extends Base
          shout: => @value .. '!'
      ]], :Base
      s = Sub!
      s.value = 'x'
      assert.equals 'X!', s\shout!
      assert.equals 'Base(X)', tostring s
      assert.equals 'fallback other', s.other
      assert.raises "property 'size' is read%-only", -> s.size = 2

    it 'pass them on to their own subclasses', ->
      Sub = moon_run 'class Sub extends Base', :Base
      Deeper = moon_run [[
        class Deeper extends Sub
          new: => super 'd'
      ]], :Sub
      assert.equals 'Base(d)', tostring Deeper!
      assert.equals 'd', Deeper!.value

    it 'still call the parent class __inherited', ->
      moon_run 'class Sub extends Base', :Base
      assert.equals 'Sub', Base.child

  it 'sees methods added to __base later, as MoonScript code does', ->
    Thing = run [[
      class Thing
        a: => 'a'
    ]]
    Thing.__base.b = => 'b'
    assert.equals 'b', Thing!\b!

  describe 'PropertyObject subclasses', ->
    Buffer = nil

    before_each ->
      Buffer = run [[
        class Buffer extends PropertyObject
          new: (@_text = '') =>
            super()
          @property(text: {
            get: => @_text
            set: (v) => @_text = v
          })
          @property(size: {get: => #@_text})
          @meta({
            __len: => #@_text
            __tostring: => "Buffer(#{@_text})"
          })
          append: (s) => @text ..= s
      ]], :PropertyObject

    it 'support properties', ->
      b = Buffer 'ab'
      b.text = 'abc'
      b\append 'd'
      assert.equals 'abcd', b.text
      assert.equals 4, b.size
      assert.raises 'read%-only', -> b.size = 3

    it 'support metamethods via @meta', ->
      b = Buffer 'xyz'
      assert.equals 3, #b
      assert.equals 'Buffer(xyz)', tostring b

    it 'can be subclassed again after being instantiated', ->
      Buffer 'x' -- installs __newindex on Buffer's base
      Sub = run [[
        class Sub extends Buffer
          text: 'not the property'
          shout: => @_text:upper()
      ]], :Buffer
      s = Sub 'hey'
      assert.equals 'HEY', s\shout!
      assert.equals 'not the property', rawget Sub.__base, 'text'
