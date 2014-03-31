import inputs from howl

describe 'inputs', ->
  after_each -> inputs.unregister 'foo'

  describe '.register(spec)', ->
    it 'raises an error if any of the mandatory inputs are missing', ->
      assert.raises 'name', -> inputs.register description: 'foo', factory: -> true
      assert.raises 'factory', -> inputs.register name: 'foo', description: 'foo'
      assert.raises 'description', -> inputs.register name: 'foo', factory: -> nil

  it '.<name> allows direct indexing of inputs', ->
    def = name: 'foo', description: 'foo', factory: -> true
    inputs.register def
    assert.same inputs.foo, def

  it '.unregister(name) removes the specified input', ->
    inputs.register name: 'foo', description: 'foo', factory: -> true
    inputs.unregister 'foo'

    assert.is_nil inputs.foo

  it 'allows iterating through inputs using pairs()', ->
    inputs.register name: 'foo', description: 'foo', factory: -> true
    names = [name for name, func in pairs inputs when name == 'foo']
    assert.same names, { 'foo' }
