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
      x = if t
        nil .. 'x'
    ]]
    assert.equals 2, error_line [[
      t = {1, 2}
      y = [x.field for x in *t]
    ]]
