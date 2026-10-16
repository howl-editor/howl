{:compile_error, :run} = require 'howlscript.spec.support'

describe 'switch', ->
  name_of = (n) ->
    run [[
      switch ...
        when 'Robert'
          return 'robert'
        when 'Dan', 'Daniel'
          return 'dan'
        else
          return 'unknown'
    ]], {}, n

  it 'picks the first matching when, comparing with ==', ->
    assert.same {'robert', 'dan', 'dan', 'unknown'}, {name_of('Robert'), name_of('Dan'), name_of('Daniel'), name_of('x')}

  it 'supports when ... then and else on one line', ->
    assert.same {'two', 'other'}, {run [[
      f = (x) ->
        switch x
          when 1 then return 'one'
          when 2 then return 'two'
          else return 'other'
      f(2), f(3)
    ]]}

  it 'evaluates the subject once', ->
    assert.same {1, 'b'}, {run [[
      calls = 0
      subject = ->
        calls += 1
        2
      local r
      switch subject()
        when 1 then r = 'a'
        when 2 then r = 'b'
      calls, r
    ]]}

  it 'tests the values in order, up to the first match', ->
    assert.same {'one', '1'}, {run [[
      log = {}
      v = (n) ->
        log[#log + 1] = n
        n
      local r
      switch 1
        when v(1), v(2) then r = 'one'
        when v(3) then r = 'three'
      r, table.concat(log, ',')
    ]]}

  it 'puts the case value on the left of ==', ->
    assert.equals 'when value on the left', run [[
      mt = {__eq: (a, b) -> a.id == 'when'}
      case = setmetatable({id: 'when'}, mt)
      local r
      switch setmetatable({id: 'subject'}, mt)
        when case then r = 'when value on the left'
        else r = 'subject on the left'
      r
    ]]

  it 'has no value', ->
    assert.match compile_error('x = switch y\n  when 1 then 2'), "'switch' is a statement and gives no value"
    assert.match compile_error('f = (y) ->\n  switch y\n    when 1 then 2'), "the 'switch' ending this function gives no value, so write 'return' before this"

  it 'needs when clauses', ->
    assert.match compile_error('switch x\nprint(1)'), "expected 'when' clauses"
