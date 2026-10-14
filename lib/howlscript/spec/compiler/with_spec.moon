{:compile_error, :run} = require 'howlscript.spec.support'

describe 'with', ->
  it 'gives .field and :method() access to its target', ->
    assert.same {'Oswald', {'dad'}}, {run [[
      person = {relatives: {}, add: (r) => @relatives[#@relatives + 1] = r}
      with person
        .name = 'Oswald'
        :add('dad')
      person.name, person.relatives
    ]]}

  it 'allows .field and :method() anywhere in expressions inside it', ->
    assert.same {'b', true}, {run [[
      obj = {a: 'b', ok: => true}
      local x, y
      with obj
        x = .a
        y = :ok() if .a == 'b'
      x, y
    ]]}

  it 'reaches its target from string interpolations', ->
    assert.equals 'n!', run [[
      obj = {name: 'n'}
      with obj
        .label = "#{.name}!"
      obj.label
    ]]

  it 'can be an argument', ->
    assert.equals 1, run [[
      f = (t) -> t
      t = f(with {}
        .v = 1
      )
      t.v
    ]]

  it 'is a value: its target', ->
    assert.equals 'x', run [[
      t = with {}
        .name = 'x'
      t.name
    ]]

  it 'returns its target as the last statement of a function', ->
    assert.equals 3, run [[
      make = ->
        with {}
          .n = 3
      make().n
    ]]

  it 'nests, the inner with taking precedence', ->
    assert.same {'outer', 'inner'}, {run [[
      a, b = {}, {}
      with a
        .v = 'outer'
        with b
          .v = 'inner'
      a.v, b.v
    ]]}

  it 'is reachable from functions inside it', ->
    assert.equals 2, run [[
      obj = {n: 1}
      with obj
        f = -> .n = 2
        f()
      obj.n
    ]]

  it 'rejects .field and :method() outside of a with', ->
    assert.match compile_error('.x = 1'), "'.x' refers to the target of a with block"
    assert.match compile_error('x = :f()'), "':f%(%)' calls a method on the target of a with block"
