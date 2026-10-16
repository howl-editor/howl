{:compile_error, :run} = require 'howlscript.spec.support'

describe 'functions', ->
  it 'return the value of their last statement', ->
    assert.equals 3, run [[
      add = (a, b) -> a + b
      add(1, 2)
    ]]

  it 'return several values from a list', ->
    assert.same {1, 2}, {run [[
      f = -> 1, 2
      f()
    ]]}

  it 'return nothing when the last statement has no value', ->
    assert.equals 0, select '#', run [[
      f = ->
        x = 1
      f()
    ]]

  it 'return nothing when the last statement is an if, or a declaration', ->
    assert.same {0, 0, 0}, {run [[
      f = (x) ->
        if x
          y = x
      g = ->
        local x
      h = ->
        x = 1
        x += 1
      select('#', f(true)), select('#', g()), select('#', h())
    ]]}

  it 'can be called right away', ->
    assert.equals 5, run '(-> 5)()'

  it 'can be empty', ->
    assert.is_nil run [[
      f = ->
      g = ->

      f() or g()
    ]]

  it 'can have a body on the same line or indented', ->
    assert.same {1, 2}, {run [[
      f = -> 1
      g = ->
        y = 2
        y
      f(), g()
    ]]}

  it 'support explicit returns', ->
    assert.equals 'early', run [[
      f = (x) ->
        return 'early' if x
        'late'
      f(true)
    ]]

  it 'can have parameter lists over several lines', ->
    assert.equals 6, run [[
      f = (a,
           b,
           c) ->
        a + b + c
      f(1, 2, 3)
    ]]

  describe 'parameters', ->
    it 'support defaults, evaluated when the argument is nil', ->
      assert.same {3, 12, false}, {run [[
        f = (a, b = 2) -> a + b
        g = (a = 'default') -> a
        f(1), f(2, 10), g(false)
      ]]}

    it 'evaluate defaults on each call', ->
      assert.is_true run [[
        f = (t = {}) -> t
        f() != f()
      ]]

    it 'let defaults use earlier parameters', ->
      assert.equals 6, run [[
        f = (a, b = a * 2) -> a + b
        f(2)
      ]]

    it 'support varargs', ->
      assert.same {3, 'c'}, {run [[
        f = (...) ->
          args = {...}
          #args, select(3, ...)
        f('a', 'b', 'c')
      ]]}

    it 'take destructuring patterns', ->
      assert.equals 'leaf -> world: hi', run [[
        send = ({:sender, :recipient, body: msg}) -> "#{sender} -> #{recipient}: #{msg}"
        send({sender: 'leaf', recipient: 'world', body: 'hi'})
      ]]

    it 'take nested patterns and defaults for them', ->
      assert.same {'origin', 1, 2}, {run [[
        f = ({label, pos: {x, y}} = {'origin', pos: {1, 2}}) -> label, x, y
        f()
      ]]}

  describe 'fat arrows', ->
    it 'take self as their first parameter', ->
      assert.equals 15, run [[
        obj = {value: 10, add: (n) => @value + n}
        obj:add(5)
      ]]

    it 'set fields of self from @ parameters, which also bind locals', ->
      assert.same {1, 2, 3}, {run [[
        obj = {init: (@a, @b) => a + b}
        sum = obj:init(1, 2)
        obj.a, obj.b, sum
      ]]}

    it 'handle @ parameters in written order, with defaults', ->
      assert.same {5, 5}, {run [[
        obj = {init: (@x = 5, y = @x) => y}
        y = obj:init()
        obj.x, y
      ]]}

    it 'reject @ parameters in thin arrows', ->
      assert.match compile_error('f = (@x) -> 1'), "needs a method, defined with '=>'"

  describe '@ and @@', ->
    it 'refer to self and its class', ->
      assert.same {'v', 'c'}, {run [[
        cls = {name: 'c'}
        obj = setmetatable({value: 'v', __class: cls}, {})
        get = => @value, @@name
        get(obj)
      ]]}

    it 'are self and its class on their own', ->
      assert.same {true, true}, {run [[
        cls = {}
        obj = setmetatable({__class: cls}, {})
        get = => @, @@
        a, b = get(obj)
        a == obj, b == cls
      ]]}

    it 'call methods on self and its class', ->
      assert.same {'hi there', 8}, {run [[
        cls = {double: (x) => x * 2}
        obj = setmetatable({
          __class: cls
          greet: (name) => @prefix() .. ' ' .. name
          prefix: => 'hi'
          double: (x) => @@double(x)
        }, {})
        obj:greet('there'), obj:double(4)
      ]]}

    it 'take fields that are Lua keywords', ->
      assert.equals 5, run [[
        obj = {end: 5, get: => @end}
        obj:get()
      ]]

    it 'reach self from thin arrows inside methods', ->
      assert.equals 2, run [[
        obj = {x: 2, get: => (-> @x)()}
        obj:get()
      ]]

    it 'are errors where there is no self', ->
      assert.match compile_error('f = -> @x'), "'@' refers to self, but there's none here"
      assert.match compile_error('x = @@y'), "'@' refers to self"

  it 'reject ... in functions not taking it', ->
    assert.match compile_error('f = -> ...'), "'...' can only be used in a function taking '...'"

  it 'allow ... in the file, as Lua chunks take it', ->
    assert.same {'a', 'b'}, {run 'return ...', {}, 'a', 'b'}
