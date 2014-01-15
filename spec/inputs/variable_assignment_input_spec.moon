import inputs, config, Buffer from howl

require 'howl.inputs.variable_assignment_input'

describe 'VariableAssignmentInput', ->

  it 'registers a "variable_assignment" input', ->
    assert.not_nil inputs.variable_assignment

  describe 'an instance of', ->
    local readline, input

    before_each ->
      readline = {}
      mode = config: {}
      _G.editor = buffer: Buffer mode
      input = inputs.variable_assignment!

    after_each -> readline = nil

    it '.should_complete() returns true', ->
      assert.is_true input\should_complete!

    describe '.on_completed(item, readline)', ->
      context 'when the assignment is incomplete', ->
        it 'returns false', ->
          readline.text = 'foo'
          assert.is_false input\on_completed { 'foo', 'foo description' }, readline

        it 'appends a "=" to the readline text', ->
          readline.text = 'foo'
          input\on_completed { 'foo', 'foo description' }, readline
          assert.equal readline.text, 'foo='

      it 'returns true if the assignment is complete', ->
        readline.text = 'foo=bar'
        assert.is_true input\on_completed { 'foo', 'foo description' }, readline

        readline.text = 'foo=Hello Whitespace Sentence'
        assert.is_true input\on_completed { 'foo', 'foo description' }, readline

    describe '.complete(text)', ->
      before_each ->
        config.define name: 'hola_var', description: 'Yes!', options: { 'two', 'one' }
        input = inputs.variable_assignment!

      context 'for the left hand side of the assignment', ->
        it 'returns variable names and descriptions', ->
          completions = [t for t in *input\complete('hola') when t[1] == 'hola_var']
          assert.same completions, { {'hola_var', 'Yes!' } }

      context 'for the right hand side of the assignment', ->
        it 'returns a sorted list of option values for a plain table', ->
          completions = input\complete('hola_var=')
          assert.same completions, { 'one', 'two' }

        it 'returns a sorted list of option value for a function generating options', ->
          config.define name: 'hola_var', description: 'Yes!', options: -> { 'two', 'one' }
          completions = input\complete('hola_var=')
          assert.same completions, { 'one', 'two' }

        it 'returns list options with `selection` set to current value if any', ->
          config.hola_var = 'two'
          _, options = input\complete('hola_var=')
          assert.equal options.list.selection, 'two'

          config.hola_var = nil
          _, options = input\complete('hola_var=')
          assert.is_nil options.list.selection

        it 'returns a sorted list of option values for options with descriptions', ->
          options = {
            { true, 'yes' }
            { false, 'no' }
          }

          config.define name: 'hola_var', description: 'Yes!', :options
          completions = input\complete('hola_var=')
          assert.same {
            { 'false', 'no' }
            { 'true', 'yes' }
          }, completions

        it 'returns nil if the variable is undefined', ->
          assert.is_nil (input\complete 'honest_politician=')

      describe '.value_for(text)', ->
        it 'returns a table containing the assignment information', ->
          value = input\value_for('foo=bar')
          assert.same value, name: 'foo', value: 'bar'
          assert.same input\value_for('foo='), name: 'foo'
          assert.same input\value_for('foo'), {}

        it 'handles whitespace separated values', ->
          value = input\value_for('foo=Frob bar')
          assert.same value, name: 'foo', value: 'Frob bar'

        it 'converts empty values to nil', ->
          value = input\value_for('foo=')
          assert.same value, name: 'foo', value: nil
