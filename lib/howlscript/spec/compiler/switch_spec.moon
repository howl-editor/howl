{:compile_error, :run} = require 'howlscript.spec.support'

describe 'switch', ->
  name_of = (n) ->
    run [[
      switch ...
        when 'Robert'
          'robert'
        when 'Dan', 'Daniel'
          'dan'
        else
          'unknown'
    ]], {}, n

  it 'picks the first matching when, comparing with ==', ->
    assert.same {'robert', 'dan', 'dan', 'unknown'}, {name_of('Robert'), name_of('Dan'), name_of('Daniel'), name_of('x')}

  it 'supports when ... then on one line', ->
    assert.equals 'two', run [[
      x = 2
      switch x
        when 1 then 'one'
        when 2 then 'two'
    ]]

  it 'can be a value', ->
    assert.same {'b', nil}, {run [[
      f = (x) ->
        r = switch x
          when 1 then 'a'
          when 2 then 'b'
        r
      f(2), f(3)
    ]]}

  it 'evaluates the subject once', ->
    assert.same {1, 'b'}, {run [[
      calls = 0
      subject = ->
        calls += 1
        2
      r = switch subject()
        when 1 then 'a'
        when 2 then 'b'
      calls, r
    ]]}

  it 'puts the case value on the left of ==', ->
    assert.equals 'matched', run [[
      mt = {__eq: (a, b) -> true}
      always = setmetatable({}, mt)
      switch setmetatable({}, mt)
        when always then 'matched'
        else 'no'
    ]]

  it 'needs when clauses', ->
    assert.match compile_error('switch x\nprint(1)'), "expected 'when' clauses"
