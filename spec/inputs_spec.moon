import inputs from vilu

describe 'inputs', ->
  after -> inputs.unregister 'foo'

  describe '.register(name, func)', ->
    it 'raises an error if any of the mandatory inputs are missing', ->
      assert_raises 'name', -> inputs.register nil, -> true
      assert_raises 'func', -> inputs.register 'foo'

  it '.<name> allows direct indexing of commands', ->
    func = -> true
    inputs.register 'foo', func
    assert_equal inputs.foo, func

  it '.unregister(name) removes the specified input', ->
    inputs.register 'foo', -> true
    inputs.unregister 'foo'

    assert_nil inputs.foo

  it 'allows iterating through inputs using pairs()', ->
    inputs.register 'foo', -> true
    names = [name for name, func in pairs inputs]
    assert_table_equal names, { 'foo' }
