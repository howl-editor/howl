{:compile, :compile_error, :run} = require 'howlscript.spec.support'

describe 'calls', ->
  it 'take parentheses touching the function', ->
    assert.equals 3, run 'math.max(1, 3)'
    assert.match compile_error('x = f (a)'), "no space is allowed between a function and the '%('"

  it 'take a string literal touching a name as the single argument', ->
    assert.same {'x', 'x'}, {run [[
      id = (s) -> s
      t = {id: id}
      id'x', t.id"x"
    ]]}

  it 'continue after a string call', ->
    assert.same {'x', 'ABC', 3, 'abab'}, {run [[
      wrap = (s) -> {v: s}
      id = (s) -> s
      P = (s) -> #s
      rep = (s) -> (n) -> s:rep(n)
      wrap'x'.v, id'abc':upper(), P'x' + P'yz', rep'ab'(2)
    ]]}

  it 'pass all the values of a last call argument, and the first of others', ->
    assert.same {1, 1, 2}, run [[
      f = -> 1, 2
      g = (...) -> {...}
      g(f(), f())
    ]]

  it 'do not make a call of a long string touching a name', ->
    assert.match compile_error('id[[x]]'), 'a long string touching a name is not a call'

  it 'do not make a call of a string after a keyword', ->
    assert.equals 'x', run "return'x'"

  it 'chain', ->
    assert.equals 'A', run [[
      make = -> (s) -> {value: s}
      make()('a').value:upper()
    ]]

  it 'can spread their arguments over lines', ->
    assert.same {1, 2, 3}, {run [[
      f = (...) -> ...
      f(
        1,
        2
        3
      )
    ]]}

  it 'continue an argument on the next line after an operator', ->
    assert.equals 6, run [[
      f = (x) -> x
      f(1 +
        2 +
        3)
    ]]

  describe 'without parentheses', ->
    it 'take the rest of the line as arguments', ->
      assert.same {1, 'two', {3}, true}, run [[
        args = nil
        f = (...) -> args = {...}
        f 1, 'two', {3}, not nil
        args
      ]]

    it 'collect trailing key: value arguments into a last table argument', ->
      assert.same {1, {a: 2, b: 3}}, run [[
        args = nil
        f = (...) -> args = {...}
        b = 3
        f 1, a: 2, :b
        args
      ]]
      assert.same {{b: 3, c: 4}}, run [[
        args = nil
        f = (...) -> args = {...}
        b = 3
        f :b, c: 4
        args
      ]]
      assert.match compile_error('f a: 1, 2'), 'positional arguments must come before the named ones'

    it 'can start with any value that does not continue an expression', ->
      assert.same {'s', 'l', {1}, false, 2, 7, true, 8, 9, 10}, run [==[
        got = {}
        f = (x) -> got[#got + 1] = type(x) == 'function' and x(8) or x
        g = (...) -> f ...
        t = {1, 2}
        f 's'
        f [[l]]
        f {1}
        f not true
        f #t
        g 7
        f true
        f (x) -> x
        f -> 9
        with {ten: 10}
          f .ten
        got
      ]==]

    it 'do not start with a minus, which subtracts', ->
      assert.equals 2, run 'f = 3\nf -1'

    it 'can end with a function and its block, where they can be used again', ->
      assert.same {'outer', 'inner', 'body'}, run [[
        log = {}
        describe = (name, fn) ->
          log[#log + 1] = name
          fn()
        describe 'outer', ->
          describe 'inner', ->
            log[#log + 1] = 'body'
        log
      ]]

    it 'continue on the next line after a trailing comma', ->
      assert.same {1, 2}, run [[
        args = nil
        f = (...) -> args = {...}
        f 1,
          2
        args
      ]]
      assert.match compile_error('f 1,\n2'), 'a continuation line must be indented deeper'

    it 'can be method calls, also on self, super and the target of a with', ->
      assert.equals 'ab!', run [[
        obj = {s: '', add: (s, bang) => @s ..= s .. (bang or '')}
        obj:add 'a'
        obj:add 'b', '!'
        obj.s
      ]]
      assert.same {'base 2', 'x'}, {run [[
        class Base
          new: (@v) =>
          show: (n) => "base #{n}"
        class Derived extends Base
          new: (v) =>
            super v
          show: (n) =>
            super n
          twice: (n) =>
            @show n * 2
        d = Derived('x')
        d:twice(1), d.v
      ]]}
      assert.same {1, 2, 3}, run [[
        obj = {items: {}, three: 3, add: (x) => @items[#@items + 1] = x}
        with obj
          :add 1
          .add obj, 2
          :add .three
        obj.items
      ]]

    it 'take statement modifiers that apply to the whole call', ->
      assert.same {1, 3}, run [[
        got = {}
        f = (x) -> got[#got + 1] = x
        f x for x in *{1, 2, 3} if x != 2
        f 4 if false
        got
      ]]

    it 'leave a statement modifier in an inline body of an argument to that body', ->
      assert.same {1, 2}, run [[
        got = {}
        each = (fn) -> fn()
        each -> got[#got + 1] = x for x in *{1, 2}
        got
      ]]

    it 'can be the inline body of a function', ->
      assert.same {1, 2}, {run [[
        f = (...) -> ...
        g = -> f 1, 2
        g()
      ]]}

    it 'can be statements of a block inside brackets', ->
      assert.equals 2, run [[
        f = (x) -> x + 1
        call = (fn) -> fn()
        call(->
          f 1
        )
      ]]

    it 'must be statements of their own', ->
      for src in *{'x = f a', 'return f a', 'local x = f a', 'export x = f a', 'n = 1 + f a', 'not f a', 'x, f a', 'x = obj:m a'}
        assert.match compile_error(src), 'only a call that is a statement of its own can leave out its parentheses'

    it 'must not be in the arguments of another on the same line', ->
      for src in *{'f 1, g 2', 'f 1, -> g 2', 'f 1, -> obj:m 2', "it 'x', -> assert.equal 1, x"}
        assert.match compile_error(src), 'a call in the arguments of a call without parentheses needs parentheses'

    it 'must not be inside brackets', ->
      for src in *{'f(a, g 1)', 'f(a, -> g 1)', 'x = {h: -> g 1}', 'f 1, {g 2}', 'x = (g 1)', 'x = t[g 1]', 'x = [g 1 for y in *t]'}
        assert.match compile_error(src), 'a call inside brackets needs parentheses'

    it 'are errors in block headers, reported as a missing then or do', ->
      assert.match compile_error('if f x then y()'), "expected 'then' or an indented block, found 'x'"
      assert.match compile_error('for x in pairs t do y()'), "expected 'do' or an indented block, found 't'"

  describe 'with a table as the only argument', ->
    it 'need no parentheses, with or without a space', ->
      assert.same {{1}, {2}, {k: 3}}, {run [[
        id = (t) -> t
        return id {1}, id{2}, id {k: 3}
      ]]}

    it 'can be used anywhere a value can', ->
      assert.same {{{1}, 'x'}, {{2}}, 3, 9, {{6}}}, {run [[
        args = (...) -> {...}
        id = (t) -> t
        a = args(id {1}, 'x')
        b = {id {2}}
        n = 0
        n += v for v in *id {4, 5}
        local got
        if id {true}
          got = args(id{6})
        return a, b, #id {1, 2, 3}, n, got
      ]]}

    it 'can be in the arguments of a call without parentheses', ->
      assert.same {1, {2}}, run [[
        args = nil
        f = (...) -> args = {...}
        id = (t) -> t
        f 1, id {2}
        args
      ]]

    it 'can be method calls, also on self and super', ->
      assert.same {{1}, {2}, {3}, {4}}, {run [[
        class Base
          m: (t) => t
        class Derived extends Base
          m: (t) => super {t[1] + 2}
          own: (t) => t
          both: => @own {4}
        obj = {m: (t) => t}
        return obj:m {1}, obj:m{2}, Derived():m({1}), Derived():both()
      ]]}

    it 'continue after the table', ->
      assert.same {'v', 'V'}, {run [[
        id = (t) -> t
        return id {k: 'v'}.k, id{k: 'v'}.k:upper()
      ]]}

    it 'take a table as comprehension as well', ->
      assert.same {a: true}, run [[
        id = (t) -> t
        x = id {k, true for k in *{'a'}}
        x
      ]]

    it 'start arguments without parentheses at the start of a statement', ->
      assert.same {{1}, 2}, run [[
        args = nil
        f = (...) -> args = {...}
        f {1}, 2
        args
      ]]

    it 'pass only the table elsewhere, as in Lua', ->
      assert.same {{1}, 2}, {run [[
        id = (t) -> t
        a, b = id {1}, 2
        return a, b
      ]]}

    it 'do not take a table from the next line', ->
      assert.same {'g', {1}}, run [[
        args = (...) -> {...}
        g = 'g'
        args(g
          {1})
      ]]

  describe 'implicit tables', ->
    it 'collect trailing key: value arguments into a last table argument', ->
      assert.same {1, {a: 2, b: 3}}, {run [[
        f = (...) -> ...
        b = 3
        f(1, a: 2, :b)
      ]]}

    it 'can have their entries on separate lines', ->
      assert.same {'x', {a: 1, b: 2, c: 3}}, {run [[
        f = (...) -> ...
        f('x',
          a: 1
          b: 2,
          c: 3
        )
      ]]}

    it 'support keyword, string and expression keys', ->
      assert.same {end: 1, ['a b']: 2, [3]: 3}, run [[
        f = (t) -> t
        f(end: 1, 'a b': 2, [1 + 2]: 3)
      ]]

    it 'reject positional arguments after named ones', ->
      assert.match compile_error('f(a: 1, 2)'), 'positional arguments must come before the named ones'

    it 'need braces for nested tables', ->
      assert.match compile_error('f(title: get: 1)'), 'wrap the value in {}'

  describe 'methods', ->
    it 'are called with :', ->
      assert.equals 'HI', run "s = 'hi'\ns:upper()"

    it 'can be called on literals', ->
      assert.same {'HI', 'x'}, {run [[
        'hi':upper(), ('%s'):format('x')
      ]]}
      assert.equals "return ('hi'):upper()", compile("'hi':upper()")

    it 'can have Lua keywords as names', ->
      assert.same {'end', 'end'}, {run [[
        obj = {end: => 'end'}
        get = -> obj
        obj:end(), get():end()
      ]]}

    it 'take a touching string as the single argument', ->
      assert.equals 'x!', run [[
        obj = {bang: (s) => s .. '!'}
        obj:bang'x'
      ]]

    it 'must be called; references to them are errors', ->
      err = compile_error 'cb = obj:method'
      assert.match err, 'method reference without a call'
      assert.match compile_error('f(obj:method)'), 'method reference without a call'

  it 'reject !', ->
    assert.match compile_error('f!'), "call with '%(%)'"
