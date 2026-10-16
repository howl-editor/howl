{:run} = require 'howlscript.spec.support'

describe 'strings', ->
  it 'keep escapes as Lua has them', ->
    assert.equals 'a\tb\n"\'\\', run [['a\tb\n"\'\\']]

  it 'interpolate #{} in double quoted strings', ->
    assert.equals 'x is 3, and nil', run [[
      x = 3
      "x is #{x}, and #{nil}"
    ]]

  it 'do not interpolate in single quoted strings', ->
    assert.equals '#{x}', run [['#{x}']]

  it 'keep a # without a { as text', ->
    assert.equals 'a # b #c', run [["a # b #c"]]

  it 'interpolate with tostring, taking the first value of a call', ->
    assert.equals '<OBJ> 1', run [[
      obj = setmetatable({}, __tostring: -> 'OBJ')
      f = -> 1, 2
      "<#{obj}> #{f()}"
    ]]

  it 'interpolate expressions with strings and braces', ->
    assert.equals 'a-b {1}', run [[
      t = {1}
      "#{table.concat({'a', 'b'}, '-')} {#{t[1]}}"
    ]]

  it 'group interpolations correctly with other operators', ->
    assert.same {6, 'v: 1!'}, {run [[
      b = 1
      x = 10 / "#{b}.5"
      y = "v: #{b}" .. '!'
      math.floor(x), y
    ]]}

  it 'can be the receiver of a method call', ->
    assert.equals 'A1', run [[
      n = 1
      "a#{n}":upper()
    ]]

  it 'can span lines, keeping the line breaks', ->
    assert.equals 'one\n  two', run [[
      'one
        two'
    ]]

  it 'support long strings, raw and without the line break after [[', ->
    assert.equals 'a\\n #{b}\n"c" \'d\'', run [==[
      [[
      a\n #{b}
      "c" 'd']]
    ]==]

  it 'handle multibyte text', ->
    assert.equals 'åäö: ö', run [[
      x = 'ö'
      "åäö: #{x}"
    ]]
