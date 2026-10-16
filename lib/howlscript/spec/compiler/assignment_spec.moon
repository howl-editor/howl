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
        fact = (n) -> if n <= 1 then 1 else n * fact(n - 1)
        p, q = 1, -> q
        fact(5), q() == q, p == 1
      ]]}

    it 'includes its own value when that is a block', ->
      assert.same {true, true, true, true, true}, {run [[
        obj = with {}
          .get = -> obj
        f = if true then -> f
        g = do
          -> g
        fs = for i = 1, 2
          -> fs
        list = [(-> list) for i = 1, 2]
        obj.get() == obj, f() == f, g() == g, fs[2]() == fs, list[1]() == list
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

    it 'declare a local when the name is new, reading the outer value', ->
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

  describe 'export', ->
    it 'makes assignments to the names global', ->
      env = {}
      run [[
        export a, b
        a = 1
        f = -> b = 2
        f()
      ]], env
      assert.same {1, 2}, {env.a, env.b}

    it 'assigns directly with `export x = ...`', ->
      env = {}
      run 'export x, y = 1, 2', env
      assert.same {1, 2}, {env.x, env.y}

    it 'has no effect on a name that is already local', ->
      env = {}
      run [[
        x = 1
        export x
        x = 2
      ]], env
      assert.is_nil rawget env, 'x'

    it 'makes all new names in its scope global with `export *`', ->
      env = {}
      run [[
        export *
        a = 1
        f = ->
          inner = 2
        f()
      ]], env
      assert.equals 1, env.a
      assert.is_function env.f
      assert.is_nil rawget env, 'inner'

  it 'treats import, from, using and extends as ordinary names', ->
    assert.same {1, 2, 3, 4}, {run [[
      import, from, using, extends = 1, 2, 3, 4
      import, from, using, extends
    ]]}
    -- MoonScript's import is a call without parentheses here, with b from t nested
    assert.match compile_error('import a, b from t'), 'a call in the arguments of a call without parentheses'

  it 'rejects Lua keywords as names', ->
    assert.match compile_error('end = 1'), "'end' is a Lua keyword"
    assert.match compile_error('x = function'), "'function' is a Lua keyword"

  it 'rejects assignment to calls', ->
    assert.match compile_error('f() = 1'), "can't assign to the result of a call"
