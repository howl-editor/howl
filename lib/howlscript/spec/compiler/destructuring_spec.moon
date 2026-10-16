{:compile, :compile_error, :run} = require 'howlscript.spec.support'

describe 'destructuring', ->
  it 'takes values by position', ->
    assert.same {1, 2}, {run [[
      {a, b} = {1, 2}
      a, b
    ]]}

  it 'takes values by key, renaming them', ->
    assert.same {'world', 'tuesday'}, {run [[
      {hello: hello, day: the_day} = {hello: 'world', day: 'tuesday'}
      hello, the_day
    ]]}

  it 'takes values of the same name with :name', ->
    assert.same {table.concat, table.insert}, {run '{:concat, :insert} = table\nconcat, insert'}

  it 'takes values by keyword, string and expression keys', ->
    assert.same {1, 2, 3, 4}, {run [[
      k = 'dyn'
      src = {end: 1, if: 2, 'a b': 3, dyn: 4}
      {end: e, if: i, 'a b': s, [k]: d} = src
      e, i, s, d
    ]]}

  it 'gives nil for missing values', ->
    assert.same {1, nil, nil}, {run [[
      src = {1}
      {a, b, :c} = src
      a, b, c
    ]]}

  it 'assigns to fields of self', ->
    assert.same {1, 2}, {run [[
      obj = {set: (t) => {@a, @b} = t}
      obj:set({1, 2})
      obj.a, obj.b
    ]]}

  it 'reads straight from a plain lookup', ->
    assert.match compile('{:a, :b} = t.x'), '^local a, b = t%.x%.a, t%.x%.b'

  it 'evaluates other values once', ->
    assert.same {1, 'x', 'y'}, {run [[
      calls = 0
      get = ->
        calls += 1
        {'x', 'y'}
      {a, b} = get()
      calls, a, b
    ]]}

  it 'handles nested patterns', ->
    assert.same {1, 2, 'green'}, {run [[
      {numbers: {first, second}, properties: {:color}} = {
        numbers: {1, 2, 3}
        properties: {color: 'green'}
      }
      first, second, color
    ]]}

  it 'assigns to existing locals, fields and indexes', ->
    assert.same {1, 2, 3}, {run [[
      a = 0
      t = {}
      {a, t.b, t[1]} = {1, 2, 3}
      a, t.b, t[1]
    ]]}

  it 'can be mixed into multiple assignments', ->
    assert.same {1, 'hi', 3}, {run [[
      f = -> 1, {message: 'hi'}, 3
      num, {:message}, last = f()
      num, message, last
    ]]}

  it 'works in for loops', ->
    assert.equals 'hello world egg head', run [[
      t = {}
      for {left, right} in *{{'hello', 'world'}, {'egg', 'head'}}
        t[#t + 1] = "#{left} #{right}"
      for _, {:a} in ipairs({{a: 'x'}})
        t[#t + 1] = a
      table.concat(t, ' ', 1, 2)
    ]]

  it 'rejects calls as targets', ->
    assert.match compile_error('{f()} = t'), "can't destructure into this expression"
