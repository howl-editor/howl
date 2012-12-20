import inputs from howl

describe 'inputs', ->
  after_each -> inputs.unregister 'foo'

  describe '.register(name, func)', ->
    it 'raises an error if any of the mandatory inputs are missing', ->
      assert.raises 'name', -> inputs.register nil, -> true
      assert.raises 'func', -> inputs.register 'foo'

  it '.<name> allows direct indexing of inputs', ->
    func = -> true
    inputs.register 'foo', func
    assert.equal inputs.foo, func

  it '.unregister(name) removes the specified input', ->
    inputs.register 'foo', -> true
    inputs.unregister 'foo'

    assert.is_nil inputs.foo

  it 'allows iterating through inputs using pairs()', ->
    inputs.register 'foo', -> true
    names = [name for name, func in pairs inputs when name == 'foo']
    assert.same names, { 'foo' }
