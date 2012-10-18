describe 'Globals', ->
  it 'callable <foo> returns true if foo can be invoked as a function', ->
    assert.is_true callable -> true
    t = setmetatable {}, __call: -> true
    assert.is_true callable t

  it 'append is an alias for table.insert', ->
    assert.equal append, table.insert
