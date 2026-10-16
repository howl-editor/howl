{:compile_error, :run} = require 'howlscript.spec.support'

describe 'conditionals', ->
  classify = (n) ->
    run [[
      n = ...
      if n < 0
        return 'negative'
      elseif n == 0
        return 'zero'
      else
        return 'positive'
    ]], {}, n

  it 'pick the branch with if, elseif and else', ->
    assert.same {'negative', 'zero', 'positive'}, {classify(-1), classify(0), classify(1)}

  it 'support unless', ->
    assert.same {'no', 'yes', 'ran'}, {run [[
      f = (x) ->
        unless x
          return 'no'
        else
          return 'yes'
      a, b = true, false
      local r
      unless a and b
        r = 'ran'
      f(false), f(true), r
    ]]}

  it 'support then, elseif and else on one line', ->
    assert.same {'a', 'b', 'c', 'ran'}, {run [[
      f = (x) -> if x == 1 then return 'a' elseif x == 2 then return 'b' else return 'c'
      g = -> unless false then return 'ran'
      f(1), f(2), f(3), g()
    ]]}

  it 'take the else on a line aligned with the if', ->
    assert.equals 'outer else', run [[
      f = (a, b) ->
        if a
          if b
            return 'inner'
        else
          return 'outer else'
      f(false, true)
    ]]

  describe 'have no value', ->
    it 'so they are errors where a value is expected', ->
      for src in *{'x = if c then 1 else 2', 'f(if c then 1)', "x = 'a' .. (if c then 'b')", 'x = unless c then 1', 'x = switch c\n  when 1 then 2'}
        assert.match compile_error(src), "is a statement and gives no value; assign or return in its branches instead"

    it 'so a function ending in one returns what its branches return', ->
      assert.same {'a', 0, 0}, {run [[
        f = (x) ->
          if x
            return 'a'
        g = (x) ->
          unless x
            y = x
        f(true), select('#', f(false)), select('#', g(false))
      ]]}

    it 'so a value or call ending a branch at the end of a function is an error, suggesting return', ->
      err = compile_error [[
        f = (x) ->
          if x
            'a'
          else
            'b'
      ]]
      assert.match err, "the 'if' ending this function gives no value, so write 'return' before this to return it"
      assert.match err, '^spec:3:5:'
      assert.match compile_error('f = (x) ->\n  if x\n    print(x)'), "the 'if' ending this function gives no value"
      assert.match compile_error('f = (x) -> unless x then 1'), "the 'unless' ending this function"
      assert.match compile_error('f = (x) -> if x then 1, 2'), "the 'if' ending this function"
      assert.match compile_error('f = (x) ->\n  if x\n    with x\n      .y = 1'), "the 'if' ending this function"
      assert.match compile_error('f = (x) ->\n  if x\n    print(x) if x'), "the 'if' ending this function"

  describe 'as statement modifiers', ->
    it 'run a statement if or unless a condition holds', ->
      assert.same {1, 2}, {run [[
        t = {}
        t[#t + 1] = 1 if true
        t[#t + 1] = 2 unless false
        t[#t + 1] = 3 if false
        t[1], t[2], t[3]
      ]]}

    it 'declare an assigned name outside the condition', ->
      assert.same {nil, 'set'}, {run [[
        x = 'set' if false
        y = 'set' if true
        x, y
      ]]}

    it 'make `return if c` return nothing when c holds', ->
      assert.same {'early', 'late'}, {run [[
        t = {}
        f = (c) ->
          t[#t + 1] = 'early'
          return if c
          t[#t + 1] = 'late'
        f(true)
        f(false)
        t[1], t[3]
      ]]}

    it 'reject `return if c then a else b`, as an if has no value', ->
      assert.match compile_error('f = (c) ->\n  return if c then 1 else 2'), "'if' is a statement and gives no value; return in its branches instead"

    it 'pass on the value of what they modify at the end of a function', ->
      assert.same {'x', 0, 2, 0}, {run [[
        f = (v) -> v if v
        g = (v) ->
          n = v * 2
          tostring(n) unless v == 0
        f('x'), select('#', f(false)), tonumber(g(1)), select('#', g(0))
      ]]}

    it 'bind to the innermost inline function body', ->
      assert.same {'x', 0}, {run [[
        each = (fn) -> fn()
        r = {}
        each(-> r[#r + 1] = 'x' if true)
        f = (v) -> v if v
        r[1], select('#', f(false))
      ]]}

  it 'reject assignment as a condition', ->
    err = compile_error [[
      if x = f()
        print(x)
    ]]
    assert.match err, 'assignment is not an expression'
    assert.match compile_error('while x = f()\n  print(x)'), 'assignment is not an expression'
    assert.match compile_error('with x = f()\n  print(x)'), 'assignment is not an expression'

  it 'need then or a block', ->
    assert.match compile_error('if x print(x)'), "expected 'then' or an indented block"
