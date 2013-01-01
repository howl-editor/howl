describe 'Globals', ->
  it 'callable <foo> returns true if foo can be invoked as a function', ->
    assert.is_true callable -> true
    t = setmetatable {}, __call: -> true
    assert.is_true callable t

  it 'append is an alias for table.insert', ->
    assert.equal append, table.insert

  it 'typeof(v) is like type(), but handles ustring, regexes and moonscript classes', ->
    assert.equal 'ustring', typeof u'foo'
    assert.equal 'regex', typeof r'foo'

    class Bar
    assert.equal 'Bar', typeof Bar!
