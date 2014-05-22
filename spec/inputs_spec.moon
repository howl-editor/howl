import inputs from howl

describe 'inputs', ->
  after_each -> inputs.unregister 'foo'

  describe '.register(spec)', ->
    it 'raises an error if any of the mandatory inputs are missing', ->
      assert.raises 'name', -> inputs.register description: 'foo', factory: -> true
      assert.raises 'factory', -> inputs.register name: 'foo', description: 'foo'
      assert.raises 'description', -> inputs.register name: 'foo', factory: -> nil

    it 'sets up a call meta method that correctly creates the input', ->
      input = name: 'foo', description: 'call me!', factory: spy.new -> nil
      inputs.register input
      inputs.foo 1, 'two'
      assert.spy(input.factory).was_called_with '', 1, 'two'

  it '.<name> allows direct indexing of inputs', ->
    def = name: 'foo', description: 'foo', factory: -> true
    inputs.register def
    assert.same inputs.foo, def

  it '.unregister(name) removes the specified input', ->
    inputs.register name: 'foo', description: 'foo', factory: -> true
    inputs.unregister 'foo'

    assert.is_nil inputs.foo

  describe 'read(input, options)', ->
    it 'raises an error unless options contains .prompt', ->
      inputs.register name: 'foo', description: 'foo', factory: -> true
      assert.raises 'prompt', -> inputs.read 'foo'

    it 'raises an error for an unknown input', ->
      assert.raises 'unknown input', -> inputs.read 'guargl', prompt: 'foo'

  it 'allows iterating through inputs using pairs()', ->
    inputs.register name: 'foo', description: 'foo', factory: -> true
    names = [name for name, func in pairs inputs when name == 'foo']
    assert.same names, { 'foo' }
