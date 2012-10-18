import config, signal from lunar

describe 'config', ->
  before_each ->
    config.reset!
    _G.editor = nil

  describe 'define(options)', ->
    it 'raises an error if name is missing', ->
      assert.raises 'name', -> config.define {}

    it 'raises an error if the description option is missing', ->
      assert.raises 'description', -> config.define name: 'foo'

  it '.definitions is a table of the current definitions, keyed by name', ->
    var = name: 'foo', description: 'foo variable'
    config.define var
    assert.equal type(config.definitions), 'table'
    assert.same config.definitions.foo, var

  describe 'set(name, value)', ->
    it 'sets <name> globally to <value>', ->
      var = name: 'foo', description: 'foo variable'
      config.define var
      config.set 'foo', 2
      assert.equal config.get('foo'), 2

    it 'an error is raised if <name> is not defined', ->
      assert.raises 'Undefined', -> config.set 'que', 'si'

    it 'setting a value of nil clears the value', ->
      var = name: 'foo', description: 'foo variale'
      config.define var
      config.set 'foo', 'bar'
      config.set 'foo', nil
      assert.is_nil config.foo

  describe 'get(name, [buffer])', ->
    before_each -> config.define name: 'var', description: 'test variable'

    context 'with no local variable available', ->
      it 'get(name) returns the global value of <name>', ->
        config.set 'var', 'hello'
        assert.equal config.get('var'), 'hello'

    context 'when buffer is specified and has a local variable set', ->
      it 'get(name) returns the local value of <name>', ->
        buffer = {}
        config.set_local 'var', 'local', buffer
        assert.equal config.get('var', buffer), 'local'

    it 'when <buffer> is omitted it checks G.editor.buffer for local values', ->
      buffer = {}
      _G.editor = :buffer
      config.set_local 'var', 'local', buffer
      assert.equal config.get('var'), 'local'

  describe 'set_local(name, value, buffer)', ->
    before_each -> config.define name: 'local', description: 'local variable'

    it 'an error is raised if <name> is not defined', ->
      assert.raises 'Undefined', -> config.set_local 'que', 'si', {}

    it 'defaults to _G.editor.buffer if buffer is not specified', ->
      buffer = {}
      _G.editor = :buffer
      config.set_local 'local', 'local'
      assert.equal config.get('local', buffer), 'local'

    it 'setting a value of nil clears the value', ->
      buffer = {}
      config.set_local 'local', 'local', buffer
      config.set_local 'local', nil, buffer
      assert.is_nil config.get 'local', buffer

    it 'raises an exception if G.editor.buffer is not available and buffer is not specified', ->
      _G.editor = nil
      assert.error -> config.set_local 'local', 'local'

  context 'when a default is provided', ->
    before_each -> config.define name: 'with_default', description: 'test', default: 123

    it 'the default value is returned if no value has been set', ->
      assert.equal config.get('with_default'), 123

    it 'if a value has been set it takes precedence', ->
      config.set 'with_default', 'foo'
      assert.equal config.get('with_default'), 'foo'

  it 'reset clears all set values, but keeps the definitions', ->
    config.define name: 'var', description: 'test'
    config.set 'var', 'set'
    config.reset!
    assert.is_not_nil config.definitions['var']
    assert.is_nil config.get 'var'

  it 'global variables can be set and get directly on config', ->
    config.define name: 'direct', description: 'test', default: 123
    assert.equal config.direct, 123
    config.direct = 'bar'
    assert.equal config.direct, 'bar'
    assert.equal config.get('direct'), 'bar'

  context 'when a validate function is provided', ->
    it 'an error is raised if the function returns falsy for to-be set value', ->
      config.define name: 'validated', description: 'test', validate: -> false
      assert.error -> config.set 'validated', 'foo'
      assert.error -> config.set_local 'validated', 'foo', {}
      config.define name: 'validated', description: 'test', validate: -> nil
      assert.error -> config.set 'validated', 'foo'
      assert.error -> config.set_local 'validated', 'foo', {}

    it 'an error is not raised if the function returns truish for to-be set value', ->
      config.define name: 'validated', description: 'test', validate: -> true
      config.set 'validated', 'foo'
      assert.equal config.get('validated'), 'foo'
      config.define name: 'validated', description: 'test', validate: -> 2
      config.set 'validated', 'foo2'
      assert.equal config.get('validated'), 'foo2'

    it 'the function is not called when clearing a value by setting it to nil', ->
      validate = Spy!
      config.define name: 'validated', description: 'test', :validate
      config.set 'validated', nil
      assert.is_false validate.called

  context 'when a convert function is provided', ->
    it 'is called with the value to be set and the return value is used instead', ->
      config.define name: 'converted', description: 'test', convert: -> 'wanted'
      config.set 'converted', 'requested'
      assert.equal config.converted, 'wanted'

  context 'when options is provided', ->
    before_each ->
      config.define
        name: 'with_options'
        description: 'test'
        options: { 'one', 'two' }

    it 'an error is raised if the to-be set value is not a valid option', ->
      assert.raises 'option', -> config.set 'with_options', 'three'

    it 'an error is not raised if the to-be set value is a valid option', ->
      config.set 'with_options', 'one'

    it 'options can be a function returning a table', ->
      config.define name: 'with_options_func', description: 'test', options: ->
        { 'one', 'two' }

      assert.raises 'option', -> config.set 'with_options_func', 'three'
      config.set 'with_options_func', 'one'

    it 'options can be a table of tables containg values and descriptions', ->
      options = {
        { 'one', 'description for one' }
        { 'two', 'description for two' }
      }

      config.define name: 'with_options_desc', description: 'test', :options

      assert.raises 'option', -> config.set 'with_options_desc', 'three'
      config.set 'with_options_desc', 'one'

  context 'when scope is provided', ->
    it 'raises an error if it is not "local" or "global"', ->
      assert.raises 'scope', -> config.define name: 'bla', description: 'foo', scope: 'blarg'

    context 'with local scope for a variable', ->
      it 'an error is raised when trying to set the global value of the variable', ->
        config.define name: 'local', description: 'test', scope: 'local'
        assert.error -> config.set 'local', 'foo'

    context 'with global scope for a variable', ->
      it 'an error is raised when trying to set the local value of the variable', ->
        config.define name: 'global', description: 'test', scope: 'global'
        assert.error -> config.set_local 'global', 'foo', {}

  context 'when type_of is provided', ->
    it 'raises an error if the type is not recognized', ->
      assert.raises 'type', -> config.define name: 'bla', description: 'foo', type_of: 'blarg'

    context 'and is "boolean"', ->
      def = nil
      before_each ->
        config.define name: 'bool', description: 'foo', type_of: 'boolean'
        def = config.definitions.bool

      it 'options are {true, false}', ->
        assert.same def.options, { true, false }

      it 'convert handles boolean types and "true" and "false"', ->
        assert.equal def.convert(true), true
        assert.equal def.convert(false), false
        assert.equal def.convert('true'), true
        assert.equal def.convert('false'), false
        assert.equal def.convert('blargh'), 'blargh'

      it 'converts to boolean upon assignment', ->
        config.bool = 'false'
        assert.equal config.bool, false

    context 'and is "number"', ->
      def = nil
      before_each ->
        config.define name: 'number', description: 'foo', type_of: 'number'
        def = config.definitions.number

      it 'convert handles numbers and string numbers', ->
        assert.equal def.convert(1), 1
        assert.equal def.convert('1'), 1
        assert.equal def.convert(0.5), 0.5
        assert.equal def.convert('0.5'), 0.5
        assert.equal def.convert('blargh'), 'blargh'

      it 'validate returns true for numbers only', ->
        assert.is_true def.validate 1
        assert.is_true def.validate 1.2
        assert.is_false def.validate '1'
        assert.is_false def.validate 'blargh'

      it 'converts to number upon assignment', ->
        config.number = '1'
        assert.equal config.number, 1

  context 'watching', ->
    before_each -> config.define name: 'trigger', description: 'watchable'

    it 'watch(name, function) register a watcher for <name>', ->
      assert.not_error -> config.watch 'foo', -> true

    it 'set invokes watchers with <name>, <value> and false', ->
      callback = Spy!
      config.watch 'trigger', callback
      config.set 'trigger', 'value'
      assert.same callback.called_with, { 'trigger', 'value', false }

    it 'set_local invokes watchers with <name>, <value> and true', ->
      callback = Spy!
      buffer = {}
      config.watch 'trigger', callback
      config.set_local 'trigger', 'value', buffer
      assert.same callback.called_with, { 'trigger', 'value', true }

    context 'when a callback raises an error', ->
      before_each -> config.watch 'trigger', -> error 'oh noes'

      it 'other callbacks are still invoked', ->
        callback = Spy!
        config.watch 'trigger', callback
        config.set 'trigger', 'value'
        assert.is_true callback.called

      it 'an error is signaled', ->
        handler = Spy!
        signal.connect_first 'error', handler
        config.set 'trigger', 'value'
        assert.is_true handler.called
