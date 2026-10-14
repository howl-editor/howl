{:compile_error, :run} = require 'howlscript.spec.support'

describe 'conditionals', ->
  classify = (n) ->
    run [[
      n = ...
      if n < 0
        'negative'
      elseif n == 0
        'zero'
      else
        'positive'
    ]], {}, n

  it 'pick the branch with if, elseif and else', ->
    assert.same {'negative', 'zero', 'positive'}, {classify(-1), classify(0), classify(1)}

  it 'support unless', ->
    assert.same {'no', 'yes'}, {run [[
      f = (x) ->
        unless x
          'no'
        else
          'yes'
      f(false), f(true)
    ]]}

  it 'negate a whole unless condition', ->
    assert.equals 'ran', run [[
      a, b = true, false
      unless a and b
        'ran'
    ]]

  it 'support then and else on one line', ->
    assert.same {'a', 'b'}, {run [[
      f = (x) -> if x then 'a' else 'b'
      f(true), f(false)
    ]]}

  it 'can be values in assignments', ->
    assert.same {'tall', 'short'}, {run [[
      x = if 1 > 0
        'tall'
      else
        'short'
      y = if false then 'tall' else 'short'
      x, y
    ]]}

  it 'assign nil to an existing name when no branch is taken', ->
    assert.is_nil run [[
      x = 1
      x = if false then 2
      x
    ]]

  it 'can be values anywhere in expressions', ->
    assert.equals 'a!', run [[
      x = true
      (if x then 'a' else 'b') .. '!'
    ]]

  it 'can be arguments', ->
    assert.same {'a', 'z'}, {run [[
      f = (...) -> ...
      x = true
      f(if x then 'a' else 'b', 'z')
    ]]}

  it 'take the else on a line aligned with the if', ->
    assert.same {'outer else', 'inner else'}, {run [[
      f = (a, b) ->
        if a
          if b
            'inner'
        else
          'outer else'
      g = (a, b) ->
        if a
          r = if b
            'inner'
          else
            'inner else'
          r
      f(false, true), g(true, false)
    ]]}

  describe 'decorators', ->
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

    it 'still return an if with then as a value', ->
      assert.equals 'b', run [[
        f = (c) ->
          return if c then 'a' else 'b'
        f(false)
      ]]

    it 'bind to the innermost inline function body', ->
      assert.same {'x', nil}, {run [[
        f = (v) -> v if v
        f('x'), f(false)
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
