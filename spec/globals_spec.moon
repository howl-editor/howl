describe 'Globals', ->
  it 'callable <foo> returns true if foo can be invoked as a function', ->
    assert_true callable -> true
    t = setmetatable {}, __call: -> true
    assert_true callable t
