-- Name resolution and the rule that parameters and loop variables don't shadow.

{:compile_error, :run} = require 'howlscript.spec.support'

describe 'scoping', ->
  it 'keeps locals declared in a block inside it', ->
    assert.same {nil, 1}, {run [[
      if true
        inner = 1
      f = ->
        inner2 = 1
        inner2
      inner, f()
    ]]}

  it 'keeps the locals of a do block inside it', ->
    assert.same {6, nil}, {run [[
      local x
      do
        a = 2
        x = a * 3
      x, a
    ]]}

  it 'gives a do block no value', ->
    assert.match compile_error('x = do 1'), "'do' is a statement and gives no value; assign or return inside it instead"
    assert.match compile_error('f = ->\n  do\n    1'), "the 'do' ending this function gives no value, so write 'return' before this"

  describe 'shadowing', ->
    it 'is an error for parameters', ->
      err = compile_error [[
        buffer = nil
        f = (buffer) -> buffer
      ]]
      assert.match err, "parameter 'buffer' shadows the local declared on line 1"
      assert.match err, '^spec:2:6:'

    it 'is an error for parameters of nested functions', ->
      assert.match compile_error([[
        f = (a) ->
          g = (b) ->
            h = (a) -> a
      ]]), "parameter 'a' shadows the local declared on line 1"

    it 'is an error for @ parameters, which declare locals', ->
      assert.match compile_error([[
        x = 1
        obj = {set: (@x) => 1}
      ]]), "parameter 'x' shadows"

    it 'is an error for destructured parameters', ->
      assert.match compile_error([[
        name = 'x'
        f = ({:name}) -> name
      ]]), "parameter 'name' shadows"

    it 'is an error for loop and comprehension variables', ->
      assert.match compile_error('v = 1\nfor k, v in pairs(t) do print(v)'), "loop variable 'v' shadows"
      assert.match compile_error('v = 1\nx = [v for v in *t]'), "loop variable 'v' shadows"
      assert.match compile_error('v = 1\nfor {v} in *t do print(v)'), "loop variable 'v' shadows"

    it 'is an error for duplicate parameters', ->
      assert.match compile_error('f = (a, a) -> a'), "parameter 'a' shadows"

    it 'does not apply to _', ->
      assert.equals 2, run [[
        _ = 0
        f = (_, a) -> [b for _, b in ipairs({a})]
        f(1, 2)[1]
      ]]

    it 'does not apply to the self of methods inside methods', ->
      assert.equals 'inner', run [[
        outer = {m: => {name: 'inner', n: => @name}}
        outer:m():n()
      ]]

    it 'does not apply to locals declared later', ->
      assert.equals 1, run [[
        f = (x) -> x
        x = 1
        f(x)
      ]]

    it 'does not apply to the name being assigned', ->
      assert.same {'a'}, run [[
        opts = {a: 1}
        names = [name for name in pairs(opts)]
        names
      ]]
      assert.same {1, 2}, run [[
        f = (searchers) ->
          opts = [opts for _, opts in pairs(searchers)]
          table.sort(opts)
          opts
        f({a: 1, b: 2})
      ]]

    it 'does not apply to globals', ->
      assert.equals 'x', run [[
        f = (type) -> type
        f('x')
      ]]

    it 'can be avoided by an explicit local', ->
      assert.equals 2, run [[
        x = 1
        f = ->
          local x = 2
          x
        f()
      ]]

  it 'rejects return, break and continue in expressions compiled to functions', ->
    assert.match compile_error('f(with t\n  return 1\n)'), "'return' can't be used here"
    assert.match compile_error([[
      for x in *t
        f(with x
          break
        )
    ]]), "'break' can't be used here"
    assert.match compile_error([[
      for x in *t
        f(with x
          continue
        )
    ]]), "'continue' can't be used here"

  it 'allows return inside blocks that are assigned', ->
    assert.equals 2, run [[
      f = ->
        x = with {}
          return 2
        x
      f()
    ]]
