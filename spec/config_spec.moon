import app, config from howl

describe 'config', ->
  before_each ->
    config.reset!
    app.editor = nil

  describe 'define(options)', ->
    it 'raises an error if name is missing', ->
      assert.raises 'name', -> config.define {}

    it 'raises an error if the description option is missing', ->
      assert.raises 'description', -> config.define name: 'foo'

  describe '.definitions', ->
    it 'is a table of the current definitions, keyed by name', ->
      var = name: 'foo', description: 'foo variable'
      config.define var
      assert.equal type(config.definitions), 'table'
      assert.same var, config.definitions.foo

    it 'writing directly to it raises an error', ->
      assert.has_error -> config.definitions.frob = 'crazy'

  describe 'set(name, value)', ->
    it 'sets <name> globally to <value>', ->
      var = name: 'foo', description: 'foo variable'
      config.define var
      config.set 'foo', 2
      assert.equal config.get('foo'), 2

    it 'an error is raised if <name> is not defined', ->
      assert.raises 'Undefined', -> config.set 'que', 'si'

    it 'setting a value of nil clears the value', ->
      var = name: 'foo', description: 'foo variable'
      config.define var
      config.set 'foo', 'bar'
      config.set 'foo', nil
      assert.is_nil config.foo

  describe 'get(name, scope, layer)', ->
    before_each -> config.define name: 'var', description: 'test variable'

    it 'returns the global value of <name>', ->
      config.set 'var', 'hello'
      assert.equal config.get('var'), 'hello'

  context 'scopes', ->
    it 'get() returns value set for specific scope', ->
      config.set 'var', 'global-value'
      config.set 'var', 'scope-value', 'scope1'
      assert.equal 'scope-value', config.get 'var', 'scope1'

    it 'get() looks up the value set() in parent scopes if necessary', ->
      config.set 'var', 'global-value'
      config.set 'var', 'top-value', 'root'
      config.set 'var', 'scope-value', 'root/scope1'
      assert.equal 'scope-value', config.get 'var', 'root/scope1'
      assert.equal 'top-value', config.get 'var', 'root/scope2'
      assert.equal 'global-value', config.get 'var', 'scope3'

  context 'layers', ->
    before_each ->
      config.define name: 'var', description: 'test variable'
      config.define_layer 'layer1'
      config.define_layer 'layer2'

    it 'set() errors for undefined layer', ->
      assert.raises 'Unknown', -> config.set 'var', 'value', '', 'no-such-layer'

    it 'get() looks up specified layer before default', ->
      config.set 'var', 'layer1-value', '', 'layer1'
      config.set 'var', 'default-value', ''
      assert.equal 'layer1-value', config.get 'var', '', 'layer1'
      assert.equal 'default-value', config.get 'var', '', 'layer2'

    it 'layers are looked up at each scope', ->
      config.set 'var', 'layer1-top', '', 'layer1'
      config.set 'var', 'layer2-top', '', 'layer2'
      config.set 'var', 'default-top', ''
      config.set 'var', 'layer1-scope', 'scope1', 'layer1'

      assert.equal 'layer1-scope', config.get 'var', 'scope1', 'layer1'
      assert.equal 'layer2-top', config.get 'var', 'scope1', 'layer2'

  context 'when a default is provided in the definition', ->
    before_each -> config.define name: 'with_default', description: 'test', default: 123

    it 'the default value is returned if no value has been set', ->
      assert.equal config.get('with_default'), 123

    it 'if a value has been set it takes precedence', ->
      config.set 'with_default', 'foo'
      assert.equal config.get('with_default'), 'foo'

  context 'when a default has been set by set_default', ->
    before_each ->
      config.define name: 'var', description: 'test variable', default: 'def-default'
      config.define_layer 'layer1'
      config.define_layer 'layer2'

    it 'set_default value takes precedence over definition default', ->
      config.set_default 'var', 'set-default', 'layer1'
      assert.equal 'set-default', config.get 'var', 'scope1', 'layer1'
      assert.equal 'def-default', config.get 'var', 'scope1'

    it 'set_default value is not persisted', ->
      with_tmpdir (dir) ->
        config.set_default 'var', 'set-default', 'layer1'
        config.save_config dir
        config.load_config true, dir
        assert.equal 'set-default', config.get 'var', 'scope1', 'layer1'
        assert.equal 'def-default', config.get 'var', 'scope1'

  it 'reset clears all set values, but keeps the definitions', ->
    config.define name: 'var', description: 'test'
    config.define name: 'var2', description: 'test'
    config.set 'var', 'set'
    config.set_default 'var2', 'set-default'

    config.reset!

    assert.is_not_nil config.definitions['var']
    assert.is_nil config.get 'var'
    assert.is_nil config.get 'var2'

  it 'global variables can be set and get directly on config', ->
    config.define name: 'direct', description: 'test', default: 123
    assert.equal config.direct, 123
    config.direct = 'bar'
    assert.equal config.direct, 'bar'
    assert.equal config.get('direct'), 'bar'

  context 'when a validate function is provided', ->
    it 'is called with the value to be set whenever the variable is set', ->
      validate = spy.new -> true
      config.define name: 'validated', description: 'test', :validate
      config.set 'validated', 'my_value'
      assert.spy(validate).was_called_with 'my_value'

    it 'an error is raised if the function returns false for to-be set value', ->
      config.define name: 'validated', description: 'test', validate: -> false
      assert.error -> config.set 'validated', 'foo'
      config.define name: 'validated', description: 'test', validate: -> nil
      assert.no_error -> config.set 'validated', 'foo'
      config.define name: 'validated', description: 'test', validate: -> true
      assert.no_error -> config.set 'validated', 'foo'

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

    context 'and is "string_list"', ->
      def = nil
      before_each ->
        config.define name: 'string_list', description: 'foo', type_of: 'string_list'
        def = config.definitions.string_list

      describe 'convert', ->
        it 'leaves string tables alone', ->
          orig = { 'hi', 'there' }
          assert.same orig, def.convert orig

        it 'converts values in other tables as necessary', ->
          orig = { 1, 2 }
          assert.same { '1', '2', }, def.convert orig

        it 'converts simple values into a table', ->
          assert.same { '1' }, def.convert '1'
          assert.same { '1' }, def.convert 1

        it 'converts a blank string into an empty table', ->
          assert.same {}, def.convert ''
          assert.same {}, def.convert '  '

        it 'converts a comma separated string into a list of values', ->
          assert.same { '1', '2' }, def.convert '1,2'
          assert.same { '1', '2' }, def.convert ' 1 ,   2 '

      it 'validate returns true for table values', ->
        assert.is_true def.validate {}
        assert.is_false def.validate '1'
        assert.is_false def.validate 23

  context 'watching', ->
    before_each -> config.define name: 'trigger', description: 'watchable'

    it 'watch(name, function) register a watcher for <name>', ->
      assert.not_error -> config.watch 'foo', -> true

    it 'set invokes watchers with <name>, <value> and false', ->
      callback = Spy!
      config.watch 'trigger', callback
      config.set 'trigger', 'value'
      assert.same callback.called_with, { 'trigger', 'value', false }

    it 'define(..) invokes watchers with <name>, <default-value> and false', ->
      callback = spy.new ->
      config.watch 'undefined', callback
      config.define name: 'undefined', description: 'springs into life', default: 123
      assert.spy(callback).was_called_with 'undefined', 123, false

    context 'when a callback raises an error', ->
      before_each -> config.watch 'trigger', -> error 'oh noes'

      it 'other callbacks are still invoked', ->
        callback = Spy!
        config.watch 'trigger', callback
        config.set 'trigger', 'value'
        assert.is_true callback.called

      it 'an error is logged', ->
        config.set 'trigger', 'value'
        assert.match log.last_error.message, 'watcher'

  describe 'proxy', ->
    config.define
      name: 'my_var'
      description: 'base'
      type_of: 'number'

    local proxy_inner, proxy_outer

    before_each ->
      config.my_var = 123
      proxy_inner = config.proxy '/outer/inner'
      proxy_outer = config.proxy '/outer'

    it 'returns a table with access to all previously defined variables', ->
      assert.equal 123, proxy_outer.my_var
      assert.equal 123, proxy_inner.my_var

    it 'changing a variable changes it locally only', ->
      proxy_inner.my_var = 321
      assert.equal 321, proxy_inner.my_var
      assert.equal 123, proxy_outer.my_var
      assert.equal 123, config.my_var

    it 'assignments are still validated and converted as usual', ->
      assert.has_error -> proxy_inner.my_var = 'not a number'
      proxy_inner.my_var = '111'
      assert.equal 111, proxy_inner.my_var

    it 'an error is raised if trying to set a variable with global scope', ->
      config.define name: 'global', description: 'global', scope: 'global'
      assert.has_error -> proxy_inner.global = 'illegal'

    it 'an error is raised if the variable is not defined', ->
      assert.raises 'Undefined', -> proxy_inner.que = 'si'

    it 'setting a value to nil clears the value', ->
      proxy_inner.my_var = 666
      proxy_inner.my_var = nil
      assert.equal 123, proxy_inner.my_var

    it 'setting a variable via a proxy invokes watchers with <name>, <value> and true', ->
      callback = spy.new ->
      config.watch 'my_var', callback
      proxy_inner.my_var = 333
      assert.spy(callback).was_called_with 'my_var', 333, true

    context 'chaining', ->
      it 'resolution automatically walks up scope hierarchy', ->
        proxy_inner.my_var = 1
        proxy_outer.my_var = 2

        assert.same 1, proxy_inner.my_var
        assert.same 2, proxy_outer.my_var

        proxy_inner.my_var = nil
        assert.same 2, proxy_inner.my_var

        proxy_outer.my_var = nil
        assert.same 123, proxy_inner.my_var

      context 'when layers are specified', ->
        local proxy_inner_layered, proxy_outer_layered, proxy_inner_mixed, proxy_inner_sub

        before_each ->
          config.define_layer 'layer:one'
          config.define_layer 'layer:sub', parent: 'layer:one'
          proxy_inner_layered = config.proxy '/outer/inner', 'layer:one'
          proxy_outer_layered = config.proxy '/outer', 'layer:one'
          proxy_inner_mixed = config.proxy '/outer/inner', 'default', 'layer:one'
          proxy_inner_sub = config.proxy '/outer/inner', 'layer:sub'

        it 'layer is checked before default values at each scope', ->
          proxy_inner_layered.my_var = 4
          proxy_inner.my_var = 3
          proxy_outer_layered.my_var = 2
          proxy_outer.my_var = 1

          assert.same 4, proxy_inner_layered.my_var

          proxy_inner_layered.my_var = nil
          assert.same 3, proxy_inner_layered.my_var

          proxy_inner.my_var = nil
          assert.same 2, proxy_inner_layered.my_var

        it 'read for a layer auto delegates up to parent layer', ->
          proxy_inner_layered.my_var = 5
          assert.same 5, proxy_inner_sub.my_var

        it 'read layer can be different from write layer', ->
          proxy_inner_layered.my_var = 4
          proxy_inner_mixed.my_var = 3

          assert.same 4, proxy_inner_mixed.my_var


  context 'replace()', ->
    before_each ->
      config.define_layer 'layer1'
      config.define_layer 'layer2'
      config.define name: 'name1', description: 'description'
      config.define name: 'name2', description: 'description'

    it 'clobbers new scope and deep copies all values from scope to new scope', ->
      config.set 'name1', 'value1', 'here', 'layer1'
      config.set 'name2', 'value2', 'here', 'layer2'

      assert.is_nil config.get 'name1', 'there', 'layer1'
      assert.is_nil config.get 'name2', 'there', 'layer2'

      config.replace 'here', 'there'

      assert.same 'value1', config.get 'name1', 'there', 'layer1'
      assert.same 'value2', config.get 'name2', 'there', 'layer2'

      -- ensure configs are not shared

      config.set 'name1', 'value1-new', 'here', 'layer1'
      assert.same 'value1', config.get 'name1', 'there', 'layer1'

  context 'merge()', ->
    before_each ->
      config.define_layer 'layer1'
      config.define_layer 'layer2'
      config.define name: 'name1', description: 'description'
      config.define name: 'name2', description: 'description'
      config.define name: 'name3', description: 'description'

    it 'deep copies values from scope to new scope, preserves other values in old scope', ->
      config.set 'name1', 'value1', 'here', 'layer1'
      config.set 'name2', 'value2', 'here', 'layer2'
      config.set 'name1', 'there-value1', 'there', 'layer1'
      config.set 'name3', 'there-value3', 'there', 'layer2'

      assert.same 'there-value1', config.get 'name1', 'there', 'layer1'
      assert.same nil, config.get 'name2', 'there', 'layer2'

      config.merge 'here', 'there'

      assert.same 'value1', config.get 'name1', 'there', 'layer1'
      assert.same 'value2', config.get 'name2', 'there', 'layer2'
      assert.same 'there-value3', config.get 'name3', 'there', 'layer2'

  context 'delete()', ->
    before_each ->
      config.define name: 'name1', description: 'description'

    it 'deletes all values at specified scope', ->
      config.set 'name1', 'val1', 'scope1'
      config.set 'name1', 'top-val'
      config.delete 'scope1'
      assert.equal 'top-val', config.get 'name1', 'scope1'

    it 'errors when trying to delete global scope', ->
      assert.raises 'global', -> config.delete ''

  context 'persistence', ->
    before_each ->
      config.define name: 'name1', description: 'description'
      config.define name: 'name2', description: 'description'
      config.define_layer 'layer1'

    it 'save_config() saves and load_config() loads the saved config', ->
      with_tmpdir (dir) ->
        config.set 'name1', 'value1'
        config.set 'name2', 'value2'
        config.save_config dir

        config.set 'name1', nil
        assert.same nil, config.get 'name1'

        config.load_config true, dir
        assert.same 'value1', config.get 'name1'
        assert.same 'value2', config.get 'name2'

    it 'non global scopes are not persisted', ->
      with_tmpdir (dir) ->
        config.set 'name1', 'value1', 'scope1'
        config.save_config dir

        config.set 'name1', 'value2', 'scope1'

        config.load_config true, dir
        assert.same nil, config.get 'name1', 'scope1'


    it 'does not save values if persist_config is false', ->
      with_tmpdir (dir) ->
        config.set 'name1', 'value1'
        config.set 'name2', 'value2'
        config.set 'persist_config', false
        config.save_config dir

        config.set 'name1', nil
        config.set 'name2', nil
        assert.same nil, config.get 'name1'

        config.load_config true, dir
        assert.same nil, config.get 'name1'
        assert.same nil, config.get 'name1', 'scope1'


    it 'saves persist_config value', ->
      with_tmpdir (dir) ->
        config.set 'name1', 'value1'
        config.set 'persist_config', false
        config.save_config dir

        config.set 'name1', nil
        assert.same nil, config.get 'name1'

        config.load_config true, dir
        assert.same false, config.get 'persist_config'

    it 'does not save buffer scopes', ->
      with_tmpdir (dir) ->
        config.set 'name1', 'value1-global'
        config.set 'name1', 'value2-buffer', 'buffer/123'
        config.save_config dir
        config.load_config true, dir
        assert.same 'value1-global', config.get 'name1', 'buffer/123'
