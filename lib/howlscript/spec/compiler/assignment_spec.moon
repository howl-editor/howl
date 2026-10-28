{:compile, :compile_error, :run} = require 'howlscript.spec.support'

describe 'assignment', ->
  it 'declares a local on the first assignment to a name', ->
    assert.match compile('x = 1'), '^local x = 1'
    env = {}
    run 'x = 1', env
    assert.is_nil rawget env, 'x'

  it 'assigns to a visible local instead of declaring a new one', ->
    assert.equals 3, run [[
      x = 1
      f = -> x = 3
      f()
      x
    ]]

  it 'declares only the new names in a multiple assignment', ->
    lua = compile [[
      a = 1
      a, b = 2, 3
    ]]
    assert.match lua, 'local b; a, b = 2, 3'
    assert.same {2, 3}, {run [[
      a = 1
      a, b = 2, 3
      a, b
    ]]}

  it 'spreads the values of a last call over the targets, and truncates others', ->
    assert.same {1, 2, 3, nil, 1, 10, nil}, {run [[
      f = -> 1, 2, 3
      a, b, c, d = f()
      e, g, h = f(), 10
      a, b, c, d, e, g, h
    ]]}

  it 'swaps values', ->
    assert.same {2, 1, {a: 2, b: 1}}, {run [[
      a, b = 1, 2
      a, b = b, a
      t = {a: 1, b: 2}
      t.a, t.b = t.b, t.a
      a, b, t
    ]]}

  describe 'visibility of a new name', ->
    it 'starts after its statement', ->
      -- `x` on the right is the global, not the new local
      env = x: 'global'
      assert.equals 'global', run 'x = x\nx', env
      assert.match compile('x = x'), '^local x = x'

    it 'includes its own value when that is a function, which can then recurse', ->
      assert.same {120, true, true}, {run [[
        fact = (n) -> n <= 1 and 1 or n * fact(n - 1)
        p, q = 1, -> q
        fact(5), q() == q, p == 1
      ]]}

    it 'includes its own value when that is a with block or a comprehension', ->
      assert.same {true, true}, {run [[
        obj = with {}
          .get = -> obj
        list = [(-> list) for i = 1, 2]
        obj.get() == obj, list[1]() == list
      ]]}

    it 'does not include tables and parenthesized functions', ->
      env = t: 'global t', d: 'global d'
      assert.same {'global t', 'global d'}, {run [[
        t = {get: -> t}
        d = (-> d)
        t.get(), d()
      ]], env}

    it 'leaves parameters and loop variables free to use the name', ->
      assert.same {3, {'a', 'b'}}, {run [[
        f = (f) -> f
        names = [names for names in *{'a', 'b'}]
        f(3), names
      ]]}

    it 'does not include the value of a local statement, as in Lua', ->
      assert.equals 'outer', run [[
        f = -> 'outer'
        g = ->
          local f = -> f()
          f()
        g()
      ]]

  it 'assigns to fields, indexes and self', ->
    assert.same {a: 1, [2]: 'two'}, run [[
      t = {}
      t.a = 1
      t[1 + 1] = 'two'
      t
    ]]

  describe 'update operators', ->
    it 'supports all the operators', ->
      assert.same {11, 4, 6, 2.5, 1, 'ab', 'x', false}, {run [[
        a, b, c, d, e, f, g, h = 1, 6, 3, 5, 7, 'a', nil, true
        a += 10
        b -= 2
        c *= 2
        d /= 2
        e %= 3
        f ..= 'b'
        g or= 'x'
        h and= false
        a, b, c, d, e, f, g, h
      ]]}

    it 'parenthesizes the right-hand side', ->
      assert.equals 1, run [[
        x = 10
        x -= 4 + 5
        x
      ]]

    it 'evaluates a complex target only once', ->
      assert.same {1, 2}, {run [[
        calls = 0
        t = {{n: 1}}
        get = ->
          calls += 1
          t[1]
        get().n += 1
        calls, t[1].n
      ]]}

    it 'declare a local when the name is new, reading the global', ->
      assert.match compile('y or= 3'), '^local y = y or 3'
      env = count: 1
      assert.same {2, 1}, {run([[
        f = ->
          count += 1
          count
        f()
      ]], env), env.count}

    it 'evaluates a complex index only once', ->
      assert.same {1, 5}, {run [[
        calls = 0
        t = {4}
        key = ->
          calls += 1
          1
        t[key()] += 1
        calls, t[1]
      ]]}

  describe '++ and --', ->
    it 'increment and decrement', ->
      assert.same {2, 0, 11}, {run [[
        a, b = 1, 1
        t = {n: 10}
        a++
        b--
        t.n++
        a, b, t.n
      ]]}

    it 'work on indexes', ->
      assert.equals 4, run [[
        t = {3}
        t[1]++
        t[1]
      ]]

    it 'are statements, not expressions', ->
      assert.not_nil compile_error 'y = x++'

  describe 'local', ->
    it 'forward declares names', ->
      assert.equals 'odd', run [[
        local is_even, is_odd
        is_even = (n) -> n == 0 and 'even' or is_odd(n - 1)
        is_odd = (n) -> n == 0 and 'odd' or is_even(n - 1)
        is_even(3)
      ]]

    it 'can shadow a local explicitly', ->
      assert.equals 1, run [[
        x = 1
        f = ->
          local x = 2
          x
        f()
        x
      ]]

  it 'assigns globals only through _G, as a new name declares a local', ->
    env = {}
    env._G = env
    run [[
      _G.a = 1
      b = 2
      f = -> _G.c = 3
      f()
    ]], env
    assert.same {1, 3}, {env.a, env.c}
    assert.is_nil rawget(env, 'b')

  it 'treats import, from, using, extends and export as ordinary names', ->
    assert.same {1, 2, 3, 4, 5}, {run [[
      import, from, using, extends, export = 1, 2, 3, 4, 5
      import, from, using, extends, export
    ]]}
    -- MoonScript's import is a call without parentheses here, with b from t nested
    assert.match compile_error('import a, b from t'), 'a call in the arguments of a call without parentheses'
    -- and its export a call whose result can't be assigned to
    assert.match compile_error('export x = 1'), "can't assign to the result of a call"

  it 'rejects Lua keywords as names', ->
    assert.match compile_error('end = 1'), "'end' is a Lua keyword"
    assert.match compile_error('x = function'), "'function' is a Lua keyword"

  it 'rejects assignment to calls', ->
    assert.match compile_error('f() = 1'), "can't assign to the result of a call"
