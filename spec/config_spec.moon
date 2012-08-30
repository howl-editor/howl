import config, signal from vilu
import Spy from vilu.spec

describe 'config', ->
  before -> config.reset!

  describe 'define(options)', ->
    it 'raises an error if name is missing', ->
      assert_raises 'name', -> config.define {}

    it 'raises an error if the description option is missing', ->
      assert_raises 'description', -> config.define name: 'foo'

  it '.definitions is a table of the current definitions, keyed by name', ->
    var = name: 'foo', description: 'foo variable'
    config.define var
    assert_table_equal config.definitions, foo: var

  describe 'set(name, value)', ->
    it 'sets <name> globally to <value>', ->
      var = name: 'foo', description: 'foo variable'
      config.define var
      config.set 'foo', 2
      assert_equal config.get('foo'), 2

    it 'an error is raised if <name> is not defined', ->
      assert_raises 'Undefined', -> config.set 'que', 'si'

  describe 'get(name, [buffer])', ->
    before -> config.define name: 'var', description: 'test variable'

    context 'with no local variable available', ->
      it 'get(name) returns the global value of <name>', ->
        config.set 'var', 'hello'
        assert_equal config.get('var'), 'hello'

    context 'when buffer is specified and has a local variable set', ->
      it 'get(name) returns the local value of <name>', ->
        buffer = {}
        config.set_local 'var', 'local', buffer
        assert_equal config.get('var', buffer), 'local'

    it 'when <buffer> is omitted it checks G.editor.buffer for local values', ->
      buffer = {}
      _G.editor = :buffer
      config.set_local 'var', 'local', buffer
      assert_equal config.get('var'), 'local'

  describe 'set_local(name, value, buffer)', ->
    before -> config.define name: 'local', description: 'local variable'

    it 'an error is raised if <name> is not defined', ->
      assert_raises 'Undefined', -> config.set_local 'que', 'si', {}

    it 'defaults to _G.editor.buffer if buffer is not specified', ->
      buffer = {}
      _G.editor = :buffer
      config.set_local 'local', 'local'
      assert_equal config.get('local'), 'local'

    it 'raises an exception if G.editor.buffer is not available and buffer is not specified', ->
      _G.editor = nil
      assert_error -> config.set_local 'local', 'local'

  context 'when a default is provided', ->
    before -> config.define name: 'with_default', description: 'test', default: 123

    it 'the default value is returned if no value has been set', ->
      assert_equal config.get('with_default'), 123

    it 'if a value has been set it takes precedence', ->
      config.set 'with_default', 'foo'
      assert_equal config.get('with_default'), 'foo'

  it 'reset clears all set values, but keeps the definitions', ->
    config.define name: 'var', description: 'test'
    config.set 'var', 'set'
    config.reset!
    assert_greater_than #[v for k,v in pairs config.definitions], 0
    assert_nil config.get 'var'

  it 'global variables can be set and get directly on config', ->
    config.define name: 'direct', description: 'test', default: 123
    assert_equal config.direct, 123
    config.direct = 'bar'
    assert_equal config.direct, 'bar'
    assert_equal config.get('direct'), 'bar'

  context 'when a validate function is provided', ->
    it 'an error is raised if the function returns falsy for to-be set value', ->
      config.define name: 'validated', description: 'test', validate: -> false
      assert_error -> config.set 'validated', 'foo'
      assert_error -> config.set_local 'validated', 'foo', {}
      config.define name: 'validated', description: 'test', validate: -> nil
      assert_error -> config.set 'validated', 'foo'
      assert_error -> config.set_local 'validated', 'foo', {}

    it 'an error is not raised if the function returns truish for to-be set value', ->
      config.define name: 'validated', description: 'test', validate: -> true
      config.set 'validated', 'foo'
      assert_equal config.get('validated'), 'foo'
      config.define name: 'validated', description: 'test', validate: -> 2
      config.set 'validated', 'foo2'
      assert_equal config.get('validated'), 'foo2'

  context 'when scope is provided', ->
    it 'raises an error if it is not "local" or "global"', ->
      assert_raises 'scope', -> config.define name: 'bla', description: 'foo', scope: 'blarg'

    context 'with local scope for a variable', ->
      it 'an error is raised when trying to set the global value of the variable', ->
        config.define name: 'local', description: 'test', scope: 'local'
        assert_error -> config.set 'local', 'foo'

    context 'with global scope for a variable', ->
      it 'an error is raised when trying to set the local value of the variable', ->
        config.define name: 'global', description: 'test', scope: 'global'
        assert_error -> config.set_local 'global', 'foo', {}

  context 'watching', ->
    before -> config.define name: 'trigger', description: 'watchable'

    it 'watch(name, function) register a watcher for <name>', ->
      assert_not_error -> config.watch 'foo', -> true

    it 'set invokes watchers with <name>, <value> and false', ->
      callback = Spy!
      config.watch 'trigger', callback
      config.set 'trigger', 'value'
      assert_table_equal callback.called_with, { 'trigger', 'value', false }

    it 'set_local invokes watchers with <name>, <value> and true', ->
      callback = Spy!
      buffer = {}
      config.watch 'trigger', callback
      config.set_local 'trigger', 'value', buffer
      assert_table_equal callback.called_with, { 'trigger', 'value', true }

    context 'when a callback raises an error', ->
      before -> config.watch 'trigger', -> error 'oh noes'

      it 'other callbacks are still invoked', ->
        callback = Spy!
        config.watch 'trigger', callback
        config.set 'trigger', 'value'
        assert_true callback.called

      it 'an error is signaled', ->
        handler = Spy!
        signal.connect_first 'error', handler
        config.set 'trigger', 'value'
        assert_true handler.called
