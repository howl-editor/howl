-- The Lua keeps every statement on the line it's on in the source, so errors point
-- at the Howlscript lines.

howlscript = require 'howlscript'
{:compile, :dedent} = require 'howlscript.spec.support'

describe 'line alignment', ->
  line_of = (lua, text) ->
    nr = 1
    for line in (lua .. '\n')\gmatch '([^\n]*)\n'
      return nr if line\find text, 1, true
      nr += 1

  error_line = (src) ->
    f = assert howlscript.loadstring dedent(src), '=spec'
    ok, err = pcall f
    assert.is_false ok
    tonumber err\match '^spec:(%d+):'

  it 'puts each statement on its source line', ->
    lua = compile [[
      a = 1


      b = 2
      f = (x) ->

        x + 1
      t = {
        one: 1

        two: 2
      }
    ]]
    assert.equals 1, line_of lua, 'local a = 1'
    assert.equals 4, line_of lua, 'local b = 2'
    assert.equals 7, line_of lua, 'return x + 1'
    assert.equals 9, line_of lua, 'one = 1'
    assert.equals 11, line_of lua, 'two = 2'

  it 'keeps the lines of calls without parentheses', ->
    lua = compile [[
      f 1,
        2
      describe 'x', ->

        g()
      y = 1
    ]]
    assert.equals 2, line_of lua, '2)'
    assert.equals 5, line_of lua, 'return g()'
    assert.equals 6, line_of lua, 'local y = 1'

  it 'keeps the lines of strings spanning lines', ->
    lua = compile "x = 'a\nb'\ny = 1"
    assert.equals 3, line_of lua, 'local y = 1'

  it 'keeps the lines of classes', ->
    lua = compile [[
      class A extends B
        new: =>
          super()

        m: =>
          @x
      y = 1
    ]]
    assert.equals 3, line_of lua, '__init(self)'
    assert.equals 6, line_of lua, 'return self.x'
    assert.equals 6, line_of lua, 'A = __hs_class' -- on the class's last line
    assert.equals 7, line_of lua, 'local y'

  it 'keeps the lines of properties, whatever the order of their accessors', ->
    lua = compile [[
      class A extends B
        property size => @n

        property text
          set: (t) =>
            @_t = t
          get: =>

            @_t
        __tostring: => 'a'
      y = 1
    ]]
    assert.equals 2, line_of lua, 'return self.n'
    assert.equals 5, line_of lua, 'set = function(self, t)'
    assert.equals 6, line_of lua, 'self._t = t'
    assert.equals 7, line_of lua, ' get = function(self)'
    assert.equals 9, line_of lua, 'return self._t'
    assert.equals 10, line_of lua, '__hs_hook(' -- on the class's last line
    assert.equals 11, line_of lua, 'local y'

  it 'reports runtime errors in accessors on the source line', ->
    assert.equals 5, error_line [[
      class Thing
        property value
          get: => 1
          set: (v) =>
            @x = v .. nil
      Thing().value = 1
    ]]

  it 'reports runtime errors on the source line', ->
    assert.equals 4, error_line [[
      f = (t) ->
        x = 1

        t.field.missing
      f({})
    ]]

  it 'reports runtime errors in methods on the source line', ->
    assert.equals 6, error_line [[
      class Thing
        new: =>
          @x = 1

        boom: =>
          @x .. nil
      Thing():boom()
    ]]

  it 'reports runtime errors in comprehensions and value blocks on the source line', ->
    assert.equals 3, error_line [[
      t = {1, 2}
      x = with t
        .missing()
    ]]
    assert.equals 2, error_line [[
      t = {1, 2}
      y = [x.field for x in *t]
    ]]
