{:compile_error, :run} = require 'howlscript.spec.support'

describe 'tables', ->
  it 'hold positional and keyed entries', ->
    assert.same {1, 2, name: 'x', ['a b']: true, [10]: 'ten'}, run [[
      {1, 2, name: 'x', 'a b': true, [5 * 2]: 'ten'}
    ]]

  it 'take a variable of the same name with :name', ->
    assert.same {hair: 'golden', height: 200, size: 40}, run [[
      hair, height = 'golden', 200
      {:hair, :height, size: 40}
    ]]

  it 'separate entries with commas, line breaks or both', ->
    assert.same {1, 2, 3, 4, name: 'superman', job: 'crime fighting'}, run [[
      {
        1, 2
        3, 4
        name: 'superman'
        job: 'crime fighting',
      }
    ]]

  it 'allow keywords as keys', ->
    assert.same {do: 1, end: 2, return: 3, if: 4, unless: 5}, run [[
      {do: 1, end: 2, return: 3, if: 4, unless: 5}
    ]]

  it 'allow a value on the line after its key', ->
    assert.same {key: 'value'}, run [[
      {
        key:
          'value'
      }
    ]]

  it 'need braces outside call arguments', ->
    assert.match compile_error('x = a: 1'), 'tables need braces'
    assert.match compile_error('return a: 1'), 'tables need braces'

  it 'need a space after the : of a key', ->
    assert.match compile_error('{a:1}'), "add a space after ':'"
    assert.match compile_error("{a:'x'}"), "add a space after ':'"
    assert.match compile_error('{a:b}'), 'method reference without a call'

  it 'can hold functions with blocks', ->
    assert.equals 5, run [[
      t = {
        f: (x) ->
          y = x + 1
          y
        g: -> 1
      }
      t.f(3) + t.g()
    ]]

  it 'allow fields and indexes that are Lua keywords', ->
    assert.same {1, 2}, {run [[
      t = {end: 1, true: 2}
      t.end, t.true
    ]]}
