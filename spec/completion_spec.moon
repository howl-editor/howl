import completion from lunar

describe 'completion', ->
  after_each -> completion.unregister 'foo'

  describe '.register(options)', ->
    it 'raises an error if any of the mandatory fields are missing', ->
      assert.raises 'name', -> completion.register nil, -> true
      assert.raises 'factory', -> completion.register name: 'foo'

  it '.<name> allows direct indexing of completions', ->
    c = name: 'foo', factory: -> {}
    completion.register c
    assert.same completion.foo, c

  it '.unregister(name) unregisters the specified completion', ->
    completion.register name: 'foo', factory: -> {}
    completion.unregister 'foo'

    assert.is_nil completion.foo

  it '.list contains all registered completions', ->
    c = name: 'foo', factory: -> {}
    completion.register c
    assert.includes completion.list, c
