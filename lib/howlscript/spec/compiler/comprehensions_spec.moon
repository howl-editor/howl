{:compile_error, :run} = require 'howlscript.spec.support'

describe 'comprehensions', ->
  describe 'list comprehensions', ->
    it 'map lists', ->
      assert.same {2, 4, 6}, run '[x * 2 for x in *{1, 2, 3}]'

    it 'filter with when', ->
      assert.same {2}, run '[x for x in *{1, 2, 3} when x % 2 == 0]'

    it 'combine several for and when clauses', ->
      assert.same {{1, 'a'}, {1, 'b'}, {3, 'b'}}, run [[
        [{x, y} for x in *{1, 2, 3} when x != 2 for y in *{'a', 'b'} when x == 1 or y == 'b']
      ]]

    it 'support numeric and generic for', ->
      assert.same {{2, 4}, {'a'}}, {run [[
        [i for i = 2, 4, 2], [k for k in pairs({a: 1})]
      ]]}

    it 'can be arguments', ->
      assert.equals '1-2', run "table.concat([x for x in *{1, 2}], '-')"

    it 'can span lines', ->
      assert.same {1, 3}, run [[
        [x for x in *{1, 2, 3}
          when x != 2]
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

    it 'filter with when', ->
      assert.same {name: 'fast'}, run [[
        thing = {color: 'red', name: 'fast'}
        {k, v for k, v in pairs(thing) when k != 'color'}
      ]]

    it 'take the key and value from a single expression', ->
      assert.same {hello: 'world', foo: 'bar'}, run [[
        {unpack(t) for t in *{{'hello', 'world'}, {'foo', 'bar'}}}
      ]]

  it 'reject comprehension variables shadowing locals', ->
    assert.match compile_error('x = 1\ny = [x for x in *t]'), "loop variable 'x' shadows"

  it 'are not a statement on their own', ->
    assert.match compile_error('[x for x in *t]\nprint(1)'), 'this comprehension does nothing'
