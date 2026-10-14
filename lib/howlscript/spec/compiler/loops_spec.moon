{:compile_error, :run} = require 'howlscript.spec.support'

describe 'loops', ->
  it 'support numeric for, with a step', ->
    assert.equals '1,3,5', run [[
      t = {}
      for i = 1, 6, 2
        t[#t + 1] = i
      table.concat(t, ',')
    ]]

  it 'support generic for', ->
    assert.equals 'a=1', run [[
      t = {}
      for k, v in pairs({a: 1})
        t[#t + 1] = "#{k}=#{v}"
      t[1]
    ]]

  it 'iterate the values of a list with *', ->
    assert.equals 'abc', run [[
      s = ''
      for c in *{'a', 'b', 'c'}
        s ..= c
      s
    ]]

  it 'evaluate the list of a * loop once', ->
    assert.same {1, 3}, {run [[
      calls = 0
      list = ->
        calls += 1
        {1, 2, 3}
      n = 0
      for x in *list()
        n += 1
      calls, n
    ]]}

  it 'iterate slices', ->
    assert.same {'b,c', 'a,c', 'c,b,a', 'b,c,d'}, {run [[
      items = {'a', 'b', 'c', 'd'}
      a, b, c, d = {}, {}, {}, {}
      a[#a + 1] = x for x in *items[2, 3]
      b[#b + 1] = x for x in *items[, 3, 2]
      c[#c + 1] = x for x in *items[3, 1, -1]
      d[#d + 1] = x for x in *items[2,]
      table.concat(a, ','), table.concat(b, ','), table.concat(c, ','), table.concat(d, ',')
    ]]}

  it 'reject slices outside of loops', ->
    assert.match compile_error('x = t[1, 2]'), 'slices can only be used in loops'

  it 'support while', ->
    assert.equals 0, run [[
      i = 3
      while i > 0
        i--
      i
    ]]

  it 'support single line bodies with do', ->
    assert.same {6, 3}, {run [[
      sum = 0
      for i = 1, 3 do sum += i
      n = 0
      while n < 3 do n++
      sum, n
    ]]}

  it 'support break', ->
    assert.equals 3, run [[
      last = nil
      for i = 1, 10
        last = i
        break if i == 3
      last
    ]]

  describe 'continue', ->
    it 'skips to the next iteration', ->
      assert.equals '1,3,5', run [[
        t = {}
        for i = 1, 6
          continue if i % 2 == 0
          t[#t + 1] = i
        table.concat(t, ',')
      ]]

    it 'jumps past locals declared after it', ->
      assert.equals '2,4', run [[
        t = {}
        for x in *{1, 2, 3, 4}
          continue unless x % 2 == 0
          y = x
          t[#t + 1] = y
        table.concat(t, ',')
      ]]

    it 'works in while loops and with a return ending the body', ->
      assert.equals 3, run [[
        f = ->
          i = 0
          while true
            i++
            continue if i < 3
            return i
        f()
      ]]

    it 'applies to the innermost loop', ->
      assert.equals 6, run [[
        n = 0
        for i = 1, 3
          for j = 1, 3
            continue if j == 2
            n += 1
          continue
        n
      ]]

    it 'is an error outside of loops', ->
      assert.match compile_error('continue'), "'continue' outside of a loop"
      assert.match compile_error('break'), "'break' outside of a loop"

  describe 'as values', ->
    it 'collect the value of each iteration', ->
      assert.same {2, 4, 6}, run [[
        doubled = for i = 1, 3
          i * 2
        doubled
      ]]

    it 'skip iterations that continue or have no value', ->
      assert.same {2, 4}, run [[
        evens = for x in *{1, 2, 3, 4}
          continue if x % 2 == 1
          x
        evens
      ]]

    it 'skip iterations where an if takes no branch', ->
      assert.same {1, 3}, run [[
        odds = for x in *{1, 2, 3}
          x if x % 2 == 1
        odds
      ]]

    it 'are collected when returned explicitly, but not as the last statement', ->
      assert.same {{1, 2}, nil}, {run [[
        f = -> return for i = 1, 2 do i
        g = -> for i = 1, 2 do tostring(i)
        f(), g()
      ]]}

    it 'can be used in expressions', ->
      assert.equals 3, run [[
        #(for i = 1, 3 do i)
      ]]

  it 'reject loop variables shadowing locals', ->
    assert.match compile_error('i = 1\nfor i = 1, 2 do print(i)'), "loop variable 'i' shadows the local declared on line 1"
    assert.match compile_error('x = 1\nfor x in *t do print(x)'), "loop variable 'x' shadows"
    assert.match compile_error('k = 1\nfor k, v in pairs(t) do print(k)'), "loop variable 'k' shadows"

  it 'allow _ to be reused', ->
    assert.equals 2, run [[
      n = 0
      for _, a in ipairs({1})
        for _, b in ipairs({1, 2})
          n = b
      n
    ]]

  describe 'decorators', ->
    it 'run a statement for each value', ->
      assert.equals 6, run [[
        sum = 0
        sum += x for x in *{1, 2, 3}
        sum
      ]]

    it 'filter with when', ->
      assert.equals 4, run [[
        sum = 0
        sum += x for x in *{1, 2, 3} when x != 2
        sum
      ]]
