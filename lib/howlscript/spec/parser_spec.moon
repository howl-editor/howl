-- The layout rules, and the MoonScript forms that Howlscript drops.

howlscript = require 'howlscript'
{:compile_error, :run} = require 'howlscript.spec.support'

describe 'howlscript.parser', ->
  describe 'layout', ->
    it 'ends a statement at the end of its line', ->
      assert.same {1, 2}, {run [[
        a = 1
        b = 2
        a, b
      ]]}

    it 'continues a line ending with an operator, comma or =', ->
      assert.same {3, 1, 2, 'x'}, {run [[
        a = 1 +
          2
        b, c =
          1, 2
        d = 'x'
        a, b, c, d
      ]]}

    it 'ignores the indentation of comment lines inside a block', ->
      assert.equals 2, run [[
        f = ->
          x = 1
        -- a comment at the start of the line
              -- an indented comment
          x + 1
        f()
      ]]

    it 'takes tabs for indentation', ->
      assert.equals 3, run "f = (x) ->\n\tif x\n\t\t3\n\telse\n\t\t4\nf(true)"

    it 'requires blocks to be indented consistently', ->
      assert.match compile_error('if x\n    a()\n  b()'), 'unexpected indentation'
      _, err = howlscript.to_lua '  x = 1'
      assert.match err, 'unexpected indentation'

    it 'ignores the indentation of lines inside brackets', ->
      assert.same {1, 2, 3}, run [[
        x = {
              1,
          2,
                3
        }
        x
      ]]

    it 'lets a block opened inside brackets end at the closing bracket', ->
      assert.same {'a', 'b'}, {run [[
        f = (fn, ...) -> fn(...)
        x = f((v) ->
          v
        , 'a')
        y = f(->
          'b')
        x, y
      ]]}

    it 'indents a block relative to the line its bracket entry starts on', ->
      assert.equals 3, run [[
        f = (a, fn) -> fn(a)
        f(1,
          (x) ->
            x + 2
        )
      ]]

    it 'lets inline bodies inside arguments and tables take the rest of the line', ->
      assert.same {1, 'z'}, {run [[
        f = (fn) -> fn()
        f(-> 1, 'z')
      ]]}
      t = run '{-> 1, 2}'
      assert.same {1, {1, 2}}, {#t, {t[1]()}}
      assert.same {1, 2}, {run [[
        f = (fn) -> fn()
        f -> 1, 2
      ]]}

    it 'ends inline bodies inside arguments and tables at a comma ending the line', ->
      assert.same {'f', 2, 'h', 3}, {run [[
        t = {
          f: -> 'f',
          g: 2,
        }
        call = (fn, x) -> fn(), x
        h, x = call(-> 'h',
          3)
        t.f(), t.g, h, x
      ]]}

    it 'reports a key taken into an inline body', ->
      assert.match compile_error('t = {f: -> 1, g: 2}'), 'the inline body before this key takes the rest of the line'
      assert.match compile_error('f(a: (x) -> x, b: 2)'), '^spec:1:16:'

    it 'ends the arguments of a call without parentheses at the end of the line', ->
      assert.same {{1}, 2}, {run [[
        args = nil
        f = (...) -> args = {...}
        f 1
        x = 2
        args, x
      ]]}

    it 'ends the arguments of a call without parentheses with a block they open', ->
      assert.same {'block', 'after'}, run [[
        log = {}
        f = (fn) -> fn()
        f ->
          log[#log + 1] = 'block'
        log[#log + 1] = 'after'
        log
      ]]
      -- unlike in parentheses, where `, x` can continue them
      assert.match compile_error('f ->\n  x()\n, 1'), "unexpected ','"

    it 'lets inline bodies return lists in statements', ->
      assert.same {1, 2}, {run [[
        f = -> 1, 2
        f()
      ]]}

    it 'ends block headers at the end of their line', ->
      assert.equals 'with', run [[
        obj = {done: false, finish: => @done = 'with'}
        with obj
          if not .done
            :finish()
        obj.done
      ]]

    it 'treats lines starting with . or : as statements of a with block', ->
      assert.match compile_error('.b = 1'), "'.b' refers to the target of a with block"
      -- so they can't continue a method chain, as in MoonScript
      assert.match compile_error('x = a\n  :b()'), 'unexpected indentation'

  describe 'MoonScript forms that are dropped', ->
    it 'rejects \\ for method calls', ->
      assert.match compile_error('obj\\m()'), "use ':', as in obj:method%(%)"

    it 'rejects calls without parentheses in an expression or nested in another', ->
      assert.match compile_error('x = f {1}'), 'only a call that is a statement of its own'
      assert.match compile_error("print 'x', f 1"), 'a call in the arguments of a call without parentheses'

    it 'rejects a space before the parentheses of a call', ->
      assert.match compile_error('f (1)'), "no space is allowed between a function and the '%('"

    it 'rejects a space before the [ of an index', ->
      assert.match compile_error('x = t [1]'), "no space is allowed before the '%['"
      assert.match compile_error('f [x for x in *t]'), "no space is allowed before the '%['"

    it 'rejects tables without braces outside call arguments', ->
      assert.match compile_error('x = a: 1, b: 2'), 'tables need braces'
      assert.match compile_error('x = f(a: b: 1)'), 'wrap the value in {}'

    it 'rejects !', ->
      assert.match compile_error('f!'), "'!' is not an operator in Howlscript"

    it 'rejects assignment as a value', ->
      assert.match compile_error('if x = f() then print(x)'), 'assignment is not an expression'
      assert.match compile_error('switch x\n  when y = 1 then 2'), 'assignment is not an expression'

    it 'rejects method references (function stubs)', ->
      assert.match compile_error('f(obj:m)'), 'method reference without a call'

    it 'rejects using', ->
      assert.match compile_error('f = (a using b) -> a'), "Howlscript has no 'using'"
      assert.match compile_error('f = (using nil) -> 1'), "Howlscript has no 'using'"

    it 'rejects class expressions', ->
      assert.match compile_error('x = class Foo'), 'a class can only be declared as a statement'

  describe 'errors', ->
    it 'report the position with the source line and a caret', ->
      err = compile_error [[
        x = 1
        y = (1 +
      ]]
      assert.equals "spec:3:1: unexpected end of input\n  \n  ^", err

    it 'report columns in characters for multibyte text', ->
      err = compile_error "x = 'åäö' y"
      assert.match err, '^spec:1:11: '
      assert.match err, "\n            %^$"

    it 'report unclosed brackets with where they opened', ->
      assert.match compile_error('f(1,\n  2'), "unclosed '%(' from line 1"

    it 'report code after return', ->
      assert.match compile_error('f = ->\n  return 1\n  x = 2'), "unreachable code after 'return'"
