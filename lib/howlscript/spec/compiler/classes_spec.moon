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
    assert.same {10, 10, true}, {run [[
      class Box
        size: 10
        items: {}
      Box().size, Box.size, Box().items == Box().items
    ]]}

  it 'are visible by name in their methods', ->
    assert.same {true, true}, {run [[
      class Node
        copy: => Node()
        @create: => @()
      Node():copy().__class == Node, Node:create().__class == Node
    ]]}

  it 'do not return anything from new, also when an if ends it', ->
    lua = compile [[
      class Box
        new: => tostring(1)
    ]]
    assert.not_match lua, 'return tostring'
    lua = compile [[
      class Box
        new: (v) =>
          if v
            tostring(v)
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

  describe 'metamethods', ->
    it 'are given in meta, by their Lua names', ->
      assert.same {'Point(1, 2)', 2}, {run [[
        class Point
          new: (x, y) => @x, @y = x, y
          meta {
            __tostring: => "Point(#{@x}, #{@y})"
            __len: => 2
          }
        p = Point(1, 2)
        tostring(p), #p
      ]]}

    it 'keep the base as the __index of a class without properties or fallbacks', ->
      assert.same {true, true}, {run [[
        class Point
          meta {__tostring: => 'point'}
        class Sub extends Point
        Point.__base.__index == Point.__base, Sub.__base.__index == Sub.__base
      ]]}

    it "call the parent's metamethod with super()", ->
      assert.equals 'sub of base', run [[
        class Base
          meta {__tostring: => 'base'}
        class Sub extends Base
          meta {__tostring: => 'sub of ' .. super()}
        tostring(Sub())
      ]]

    it 'leave meta as an ordinary name elsewhere', ->
      assert.same {'member', 'called', 'call'}, {run [[
        meta = (t) -> t.x
        y = meta {x: 'call'}
        class Thing
          @meta: (t) => @log = t.name
          @meta({name: 'called'})
          meta: 'member'
        Thing().meta, Thing.log, y
      ]]}

    it 'reject metamethods as members', ->
      assert.match compile_error('class A\n  __tostring: => "a"'),
        "'__tostring' is a metamethod; write 'meta {__tostring: ...}'"
      assert.match compile_error("class A\n  '__index': => 1"), "'__index' is a metamethod"

    it 'reject names that are not metamethods', ->
      assert.match compile_error('class A\n  meta {__tostirng: => "a"}'),
        "'__tostirng' isn't one of Lua's metamethods"
      assert.match compile_error('class A\n  meta {tostring: => "a"}'), "'tostring' isn't one"

    it 'reject entries without a name', ->
      assert.match compile_error('class A\n  meta {[k]: 1}'), "'meta' takes metamethods by name"
      assert.match compile_error('class A\n  meta {f}'), "'meta' takes metamethods by name"
      assert.match compile_error('class A\n  meta {k, v for k, v in pairs(t)}'),
        "'meta' takes a table of metamethods"

    it 'reject a metamethod given twice', ->
      assert.match compile_error('class A\n  meta {\n    __len: => 1\n    __len: => 2\n  }'),
        "4:5: '__len' is given twice in 'meta'"

    it 'reject a second meta in a class', ->
      assert.match compile_error('class A\n  meta {__len: => 1}\n  meta {__eq: => true}'),
        "3:3: 'meta' is already given on line 2 of this class"

    it 'reject meta without braces', ->
      assert.match compile_error('class A\n  meta __tostring: => "a"'),
        "'meta' takes a table; write 'meta {__tostring: ...}'"

  describe 'properties', ->
    range = [[
      class Range
        new: (first, last) => @first, @last = first, last
        get empty: => @last < @first
        get size: =>
          return 0 if @empty
          @last - @first + 1
    ]]

    with_range = (src) -> run dedent(range) .. '\n' .. dedent(src)

    it 'are read-only with only a getter', ->
      assert.same {true, 0, 3}, {with_range [[
        Range(2, 1).empty, Range(2, 1).size, Range(2, 4).size
      ]]}

    it 'take a getter and a setter', ->
      assert.same {'ab', 'CD', nil}, {run [[
        class Name
          new: (v) => @_v = v
          get value: => @_v
          set value: (v) => @_v = v:upper()
        n = Name('ab')
        before = n.value
        n.value = 'cd'
        before, n.value, rawget(n, 'value')
      ]]}

    it 'pair accessors given apart and in any order', ->
      assert.same {'CD', 'm'}, {run [[
        class Name
          set value: (v) => @_v = v:upper()
          m: => 'm'
          get value: => @_v
        n = Name()
        n.value = 'cd'
        n.value, n:m()
      ]]}

    it 'can be set-only', ->
      assert.equals 5, run [[
        class Widget
          set max_height: (h) => @_max_height = h
        w = Widget()
        w.max_height = 5
        w._max_height
      ]]

    it 'take any expression as an accessor', ->
      assert.same {'got', 'arrow'}, {run [[
        getter = => 'got'
        class Thing
          get value: getter
          get other: -> 'arrow'
        Thing().value, Thing().other
      ]]}

    it 'raise an error when setting a read-only one, at the assignment', ->
      assert.equals "spec:4: property 'size' is read-only", run [[
        class Range
          get size: => 1
        ok, err = pcall(->
          Range().size = 3
        )
        err
      ]]

    it 'raise an error when reading a set-only one, at the read', ->
      assert.equals "spec:5: property 'height' is write-only", run [[
        class Widget
          set height: (h) =>
          meta {__index: (key) => 'fallback'}
        ok, err = pcall(->
          Widget().height
        )
        err
      ]]

    it 'return nothing from setters, also when an if ends one', ->
      lua = compile [[
        class Name
          set value: (v) =>
            if v
              tostring(v)
      ]]
      assert.not_match lua, 'return tostring'

    it 'go through the setter for assignments in the constructor', ->
      assert.equals 'X', run [[
        class Name
          new: (value) => @value = value
          get value: => @_v
          set value: (v) => @_v = v:upper()
        Name('x')._v
      ]]

    it 'work in a constructor before super() is called', ->
      assert.equals 'x', run [[
        class Base
          get name: => @_name
          set name: (n) => @_name = n
        class Sub extends Base
          new: =>
            @name = 'x'
            super()
        Sub().name
      ]]

    it 'are inherited, also by subclasses without properties of their own', ->
      assert.same {3, true, false}, {with_range [[
        class Span extends Range
        class Labeled extends Span
          label: 'x'
        Labeled(1, 3).size, Labeled(1, 0).empty,
          Labeled.__base.__properties == Range.__base.__properties
      ]]}

    it "keep the parent's setter when a subclass gives only a getter", ->
      assert.same {'<X>', 'X'}, {run [[
        class Base
          get value: => @_v
          set value: (v) => @_v = v:upper()
        class Sub extends Base
          get value: => "<#{@_v}>"
        s = Sub()
        s.value = 'x'
        s.value, s._v
      ]]}

    it "keep the parent's getter when a subclass gives only a setter", ->
      assert.same {'X', 'base'}, {run [[
        class Base
          get value: => @_v
          set value: (v) => @_v = v
        class Sub extends Base
          set value: (v) => @_v = v:upper()
        s = Sub()
        s.value = 'x'
        b = Base()
        b.value = 'base'
        s.value, b.value
      ]]}

    it "let a subclass replace both of its parent's accessors, with any functions", ->
      assert.same {false, nil}, {run [[
        class Base
          get modified: => @_modified
          set modified: (v) => @_modified = v
        class Never extends Base
          get modified: -> false
          set modified: ->
        n = Never()
        n.modified = true
        n.modified, n._modified
      ]]}

    it "keep a subclass's property read-only when its parent's is", ->
      assert.same {'sub', true}, {run [[
        class Base
          get value: => 'base'
        class Sub extends Base
          get value: => 'sub'
        s = Sub()
        ok, err = pcall(-> s.value = 1)
        s.value, err:match("property 'value' is read%-only") != nil
      ]]}

    it "stay out of their parent's and siblings' instances", ->
      assert.same {'a', nil, nil}, {run [[
        class Base
        class A extends Base
          get name: => 'a'
        class B extends Base
        A().name, B().name, Base().name
      ]]}

    it 'win over members of the same name in subclasses', ->
      assert.equals 'property', run [[
        class Base
          get value: => 'property'
        class Sub extends Base
          value: 'member'
        Sub().value
      ]]

    it "call the parent's accessor with super()", ->
      assert.same {'<BASE>', 'BASE'}, {run [[
        class Base
          get value: => @_v
          set value: (v) => @_v = v:upper()
        class Sub extends Base
          get value: => "<#{super()}>"
          set value: (v) => super(v)
        s = Sub()
        s.value = 'base'
        s.value, s._v
      ]]}

    it 'reach the methods of the parent with super:method()', ->
      assert.equals 'sub of base', run [[
        class Base
          describe: => 'base'
        class Sub extends Base
          get description: => 'sub of ' .. super:describe()
        Sub().description
      ]]

    it 'work at the bottom of a chain whose other classes have none, with the methods inherited', ->
      assert.same {'popup closed', 'empty'}, {run [[
        class Popup
          close: => @closed = true
          describe: => 'popup'
        class Menu extends Popup
          choose: =>
            @close()
            @describe() .. (@closed and ' closed' or '')
        class Completion extends Menu
          new: => @items = {}
          get state: => #@items == 0 and 'empty' or 'full'
        c = Completion()
        c:choose(), c.state
      ]]}

    it 'find members added to the base later, as MoonScript code does', ->
      assert.same {nil, 'b', 1}, {run [[
        class Thing
          get one: => 1
        t = Thing()
        before = t.b
        Thing.__base.b = => 'b'
        before, t:b(), t.one
      ]]}

    it "keep a subclass's member set to false over its parent's", ->
      assert.same {false, 'menu'}, {run [[
        class Menu
          flair: 'menu'
        class Completion extends Menu
          flair: false
          get empty: => true
        Completion().flair, Menu().flair
      ]]}

    it 'leave get and set as ordinary names elsewhere', ->
      assert.same {'got a', 'b set', 'called x', 'member'}, {run [[
        get = (x) -> _G.called = "called #{x}"
        class Thing
          get: (k) => "got #{k}"
          set: (k) => "#{k} set"
          @get: 'class'
          get 'x'
          property: 'member'
        t = Thing()
        t:get('a'), t:set('b'), _G.called, t.property
      ]]}

    it 'reject parameters for a getter', ->
      assert.match compile_error('class A\n  get x: (a) => a'), "2:11: a getter takes no parameters"

    it 'reject an accessor without the colon', ->
      assert.match compile_error('class A\n  get x => 1'), "2:9: an accessor's name takes a ':'; write 'get x: ...'"
      assert.match compile_error('class A\n  set x (v) => v'), "write 'set x: ...'"
      assert.match compile_error('class A\n  set x(v) -> v'), "write 'set x: ...'"

    it 'reject an accessor given twice', ->
      assert.match compile_error('class A\n  get x: => 1\n  set x: (v) =>\n  get x: => 2'),
        "4:7: 'get x' is already given on line 2 of this class"

    it 'reject a name both a property and a member in a class', ->
      assert.match compile_error('class A\n  x: 1\n  get x: => 2'),
        "'x' is already defined on line 2 of this class"
      assert.match compile_error("class A\n  set x: (v) =>\n  'x': 1"),
        "'x' is already defined as a property on line 2 of this class"

  describe 'fallbacks', ->
    -- new fields go to __newindex: as well, so the constructor sets its field raw
    proxy = [[
      class Proxy
        new: (target) => rawset(self, 'target', target)
        get size: => 1
        m: => 'm'
        meta {
          __index: (key) => @target[key]
          __newindex: (key, value) => @target[key] = value
        }
    ]]

    with_proxy = (src) -> run dedent(proxy) .. '\n' .. dedent(src)

    it 'call __index: for keys that are not fields, properties or methods', ->
      assert.same {'A', 'm', 1, 't', nil}, {with_proxy [[
        p = Proxy({a: 'A', m: 'no', size: 'no'})
        p.a, p:m(), p.size, p.target and 't', p.missing
      ]]}

    it 'call __newindex: for assignments to keys that are not fields or properties', ->
      assert.same {'v', nil, 'w'}, {with_proxy [[
        t = {}
        p = Proxy(t)
        p.x = 'v'
        rawset(p, 'y', 'old')
        p.y = 'w'
        t.x, t.y, rawget(p, 'y')
      ]]}

    it 'take tables, as in Lua', ->
      assert.same {'d', 'v'}, {run [[
        store = {}
        class Defaults
          meta {
            '__index': {color: 'd'}
            __newindex: store
          }
        d = Defaults()
        d.size = 'v'
        d.color, store.size
      ]]}

    it 'are inherited', ->
      assert.same {'A', 'v'}, {with_proxy [[
        class SubProxy extends Proxy
        t = {a: 'A'}
        p = SubProxy(t)
        p.x = 'v'
        p.a, t.x
      ]]}

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

  describe 'inheritance', ->
    hierarchy = [[
      class Inventory
        new: (size) =>
          @size = size
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

    it 'passes the arguments of super(...) on to the parent method', ->
      assert.same {'a', 'b', 'c'}, run [[
        class Base
          show: (...) => {...}
        class Sub extends Base
          show: (...) => super(...)
        Sub():show('a', 'b', 'c')
      ]]

    it 'calls any parent method with super:method()', ->
      assert.equals 'backpack, a inventory', with_hierarchy [[
        BackPack(1):describe()
      ]]

    it 'calls the parent version of methods with string and expression keys', ->
      assert.same {'sub base str', 'sub base dyn'}, {run [[
        k = 'dyn'
        class Base
          'str key': => 'base str'
          [k]: => 'base dyn'
        class Sub extends Base
          'str key': => 'sub ' .. super()
          [k]: => 'sub ' .. super()
        s = Sub()
        s['str key'](s), s:dyn()
      ]]}

    it 'calls the parent class function of the same name with super() in class methods', ->
      assert.equals 'sub base Sub, other 1, f', run [[
        class Base
          @make: => 'base ' .. @__name
          @other: (x) => 'other ' .. x
          @field: 'f'
        class Sub extends Base
          @make: => "sub #{super()}, #{super:other(1)}, #{super.field}"
        Sub:make()
      ]]

    it 'calls super from functions inside a method', ->
      assert.equals 'sub base', run [[
        class Base
          m: => 'base'
        class Sub extends Base
          m: =>
            f = -> super()
            'sub ' .. f()
        Sub():m()
      ]]

    it 'calls each parent in turn over several levels', ->
      assert.same {'cba', {'a', 'b', 'c'}}, {run [[
        class A
          new: => @log = {'a'}
          m: => 'a'
        class B extends A
          new: =>
            super()
            table.insert(@log, 'b')
          m: => 'b' .. super()
        class C extends B
          new: =>
            super()
            table.insert(@log, 'c')
          m: => 'c' .. super()
        c = C()
        c:m(), c.log
      ]]}

    it 'inherits metamethods, which subclasses can override', ->
      assert.same {'P3', 'P3', 'S3', 'P3'}, {run [[
        class Point
          new: (x) => @x = x
          meta {__tostring: => "P#{@x}"}
        class Sub extends Point
        class Other extends Sub
          meta {__tostring: => "S#{@x}"}
        class Deeper extends Sub
        tostring(Point(3)), tostring(Sub(3)), tostring(Other(3)), tostring(Deeper(3))
      ]]}

    it 'compares instances of a parent and a subclass with an inherited __eq', ->
      assert.same {true, false}, {run [[
        class Point
          new: (x) => @x = x
          meta {__eq: (other) => @x == other.x}
        class Sub extends Point
        Point(1) == Sub(1), Point(1) == Sub(2)
      ]]}

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
