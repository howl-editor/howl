{:compile, :compile_error, :run} = require 'howlscript.spec.support'

describe 'calls', ->
  it 'need parentheses touching the function', ->
    assert.equals 3, run 'math.max(1, 3)'
    assert.match compile_error('print 1, 2'), 'function calls need parentheses'
    assert.match compile_error('print(f 1)'), 'function calls need parentheses'
    assert.match compile_error('x = f (a)'), "no space is allowed between a function and the '%('"

  it 'take a string literal touching a name as the single argument', ->
    assert.same {'x', 'x'}, {run [[
      id = (s) -> s
      t = {id: id}
      id'x', t.id"x"
    ]]}

  it 'do not make a call of a long string', ->
    assert.match compile_error('id[==[x]==]'), 'function calls need parentheses'

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
