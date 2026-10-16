{:compile_error, :run} = require 'howlscript.spec.support'

describe 'comprehensions', ->
  describe 'list comprehensions', ->
    it 'map lists', ->
      assert.same {2, 4, 6}, run '[x * 2 for x in *{1, 2, 3}]'

    it 'filter with if and unless', ->
      assert.same {{2}, {1, 3}}, {run [[
        [x for x in *{1, 2, 3} if x % 2 == 0], [x for x in *{1, 2, 3} unless x == 2]
      ]]}

    it 'reject when as a filter, and an if before the for', ->
      assert.match compile_error('r = [x for x in *t when x > 1]'), "filter with 'if' or 'unless' rather than 'when'"
      assert.match compile_error('r = [x if x > 1 for x in *t]'), "a comprehension's 'if' goes after its 'for'"

    it 'combine several for and if clauses', ->
      assert.same {{1, 'a'}, {1, 'b'}, {3, 'b'}}, run [[
        [{x, y} for x in *{1, 2, 3} if x != 2 for y in *{'a', 'b'} if x == 1 or y == 'b']
      ]]

    it 'support slices and destructuring', ->
      assert.same {{2, 3}, {3, 7}}, {run [==[
        items = {1, 2, 3, 4}
        [x for x in *items[2, 3]], [a + b for {a, b} in *{{1, 2}, {3, 4}}]
      ]==]}

    it 'support numeric and generic for', ->
      assert.same {{2, 4}, {'a'}}, {run [[
        [i for i = 2, 4, 2], [k for k in pairs({a: 1})]
      ]]}

    it 'can be arguments', ->
      assert.equals '1-2', run "table.concat([x for x in *{1, 2}], '-')"

    it 'can span lines', ->
      assert.same {1, 3}, run [[
        [x for x in *{1, 2, 3}
          if x != 2]
      ]]

    it 'take a function ending at the for', ->
      assert.equals 2, run [[
        fs = [-> x for x in *{1, 2}]
        fs[2]()
      ]]

    it 'need a for clause', ->
      assert.match compile_error('x = [1, 2]'), "expected 'for'"

  describe 'table comprehensions', ->
    it 'build tables from keys and values', ->
      assert.same {a: 'A', b: 'B'}, run [[
        {k, k:upper() for k in *{'a', 'b'}}
      ]]

    it 'combine several for clauses', ->
      assert.same {a1: true, a2: true, b1: true, b2: true}, run [[
        {x .. y, true for x in *{'a', 'b'} for y in *{'1', '2'}}
      ]]

    it 'filter with if and unless', ->
      assert.same {{name: 'fast'}, {color: 'red'}}, {run [[
        thing = {color: 'red', name: 'fast'}
        {k, v for k, v in pairs(thing) if k != 'color'}, {k, v for k, v in pairs(thing) unless k == 'name'}
      ]]}

    it 'take the key and value from a single expression', ->
      assert.same {hello: 'world', foo: 'bar'}, run [[
        {unpack(t) for t in *{{'hello', 'world'}, {'foo', 'bar'}}}
      ]]

  it 'reject comprehension variables shadowing locals', ->
    assert.match compile_error('x = 1\ny = [x for x in *t]'), "loop variable 'x' shadows"

  it 'are not a statement on their own', ->
    assert.match compile_error('[x for x in *t]\nprint(1)'), 'this comprehension does nothing'
