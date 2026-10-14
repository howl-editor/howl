{:compile, :compile_error, :dedent, :run} = require 'howlscript.spec.support'

describe 'classes', ->
  it 'create instances, calling new with the arguments', ->
    assert.same {'t-shirt', 2}, {run [[
      class Inventory
        new: =>
          @items = {}
        add_item: (name) =>
          if @items[name]
            @items[name] += 1
          else
            @items[name] = 1
      inv = Inventory()
      inv:add_item('t-shirt')
      inv:add_item('t-shirt')
      next(inv.items), inv.items['t-shirt']
    ]]}

  it 'share properties between instances', ->
    assert.same {10, 10}, {run [[
      class Box
        size: 10
      Box().size, Box.size
    ]]}

  it 'do not return anything from new', ->
    lua = compile [[
      class Box
        new: => tostring(1)
    ]]
    assert.not_match lua, 'return tostring'

  it 'have the class layout of MoonScript', ->
    assert.same {true, true, 'Thing', true, true}, {run [[
      class Thing
        m: => 1
      t = Thing()
      getmetatable(t) == Thing.__base, Thing.__base.__index == Thing.__base,
        Thing.__name, t.__class == Thing, Thing.m == Thing.__base.m
    ]]}

  it 'define class variables with @name:', ->
    assert.same {0, nil}, {run [[
      class Counter
        @count: 0
      Counter.count, Counter().count
    ]]}

  it 'run class body statements with self as the class', ->
    assert.same {2, 'x'}, {run [[
      class Things
        @register: (name) => @registered = name
        @register('x')
        @n = 2
      Things.n, Things.registered
    ]]}

  it 'keep locals in the class body, visible to all methods', ->
    assert.equals 'LOG: 123', run [[
      class MoreThings
        log = (msg) -> 'LOG: ' .. msg
        some_method: => log(secret)
        secret = 123
      MoreThings():some_method()
    ]]

  it 'access the class with @@', ->
    assert.equals 2, run [[
      class Counter
        @count: 0
        new: =>
          @@count += 1
      Counter()
      Counter()
      Counter.count
    ]]

  it 'support :name as short for name: name', ->
    assert.equals 'hi', run [[
      greet = => 'hi'
      class Polite
        :greet
      Polite():greet()
    ]]

  it 'allow metamethods', ->
    assert.equals 'Point(1, 2)', run [[
      class Point
        new: (@x, @y) =>
        __tostring: => "Point(#{@x}, #{@y})"
      tostring(Point(1, 2))
    ]]

  it 'allow keys that are Lua keywords and expressions', ->
    assert.same {1, 2}, {run [[
      class Odd
        end: => 1
        ['a' .. 'b']: 2
      o = Odd()
      o:end(), o.ab
    ]]}

  it 'are returned when last in a file', ->
    assert.equals 'Last', run('class Last').__name

  it 'can be exported', ->
    env = {}
    run 'export class Global', env
    assert.equals 'Global', env.Global.__name

  describe 'inheritance', ->
    hierarchy = [[
      class Inventory
        new: (@size) =>
          @items = {}
        add_item: (name) =>
          @items[#@items + 1] = name
        describe: => 'inventory'
        @kind: => 'class ' .. @__name

      class BackPack extends Inventory
        new: (size) =>
          super(size * 2)
        add_item: (name) =>
          error('backpack is full') if #@items >= @size
          super(name)
        describe: => 'backpack, a ' .. super:describe()
    ]]

    with_hierarchy = (src) -> run dedent(hierarchy) .. '\n' .. dedent(src)

    it 'calls the parent constructor with super, or by default', ->
      assert.same {4, 3}, {with_hierarchy [[
        class Bag extends Inventory
        BackPack(2).size, Bag(3).size
      ]]}

    it 'calls the parent method of the same name with super()', ->
      assert.same {'a', 'backpack is full'}, {with_hierarchy [[
        b = BackPack(0.5)
        b:add_item('a')
        ok, err = pcall(b.add_item, b, 'b')
        b.items[1], err:match('backpack is full')
      ]]}

    it 'calls any parent method with super:method()', ->
      assert.equals 'backpack, a inventory', with_hierarchy [[
        BackPack(1):describe()
      ]]

    it 'reaches the parent class with super and super.field', ->
      assert.same {true, true}, {with_hierarchy [[
        class Probe extends Inventory
          get: => super == Inventory, super.describe == Inventory.describe
        Probe():get()
      ]]}

    it 'inherits class variables and methods', ->
      assert.equals 'class BackPack', with_hierarchy [[
        BackPack:kind()
      ]]

    it 'calls __inherited on the parent', ->
      assert.equals 'Shelf was inherited by Cupboard', run [[
        class Shelf
          @__inherited: (child) => @log = "#{@__name} was inherited by #{child.__name}"
        class Cupboard extends Shelf
        Shelf.log
      ]]

    it 'adds members raw, past a __newindex on the parent base', ->
      assert.equals 'method', run [[
        class Base
        Base.__base.__newindex = (k, v) => error('set ' .. k)
        class Child extends Base
          name: 'method'
        Child.__base.name
      ]]

  it 'reject super outside of methods', ->
    assert.match compile_error('super(1)'), "'super' can only be used in a class method"
    assert.match compile_error('class A extends B\n  @x(super(1))'), "'super' can only be used in a class method"

  it 'reject super without a parent class', ->
    assert.match compile_error('class A\n  m: => super()'), "'super' needs a parent class"
