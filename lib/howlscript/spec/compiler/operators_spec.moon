{:compile_error, :run} = require 'howlscript.spec.support'

describe 'operators', ->
  it 'have Lua`s precedence', ->
    assert.same {7, -4, 2, true, 'ab2', false, 1, 0.5}, {run [[
      1 + 2 * 3, -2^2, (1 + 1) * 1, 1 < 2 and 2 < 3, 'a' .. 'b' .. 1 + 1, not 1 == 2, -2 % 3, 2^-1
    ]]}

  it 'associate ^ to the right, and arithmetic to the left', ->
    assert.same {512, 4, 2}, {run [[
      2^3^2, 7 - 2 - 1, 8 / 2 / 2
    ]]}

  it 'give the value of an operand with and and or', ->
    assert.same {1, false, 2, 'd'}, {run [[
      nil or 1, false and 1, 1 and 2, nil and nil or 'd'
    ]]}

  it 'keep the grouping of the source', ->
    assert.same {9, 0, 2, -9}, {run [[
      (1 + 2) * 3, 2 - (1 + 1), 2^(3 - 2), -(4 + 5)
    ]]}

  it 'subtract when a minus follows a value', ->
    assert.equals 1, run [[
      x = 3
      x -2
    ]]

  it 'support != and ~= for inequality', ->
    assert.same {true, false}, {run '1 != 2, 1 ~= 1'}

  it 'support not, # and unary minus', ->
    assert.same {false, 3, -1, 1}, {run [[
      x = 1
      not true, #'abc', -x, - -x
    ]]}

  it 'continue an expression on the next line after an operator', ->
    assert.equals 6, run [[
      x = 1 +
        2 +
        3
      x
    ]]

  it 'need a continuation line to be indented', ->
    assert.match compile_error('x = 1 +\n2'), 'continuation line must be indented deeper'

  it 'truncate multiple values in parentheses', ->
    assert.equals 1, select '#', run [[
      f = -> 1, 2
      (f())
    ]]
