import app, command, inputs, config, keymap from howl

describe 'command', ->
  local cmd, readline

  before_each ->
    readline = {
      read: spy.new (rl, prompt, input, opts = {}) ->
        rl.prompt = prompt
        rl.text = opts.text or ''
    }
    app.window = :readline
    cmd = name: 'foo', description: 'desc', handler: spy.new -> true

  after_each ->
    command.unregister name for name in *command.names!
    app.window = nil

  describe '.register(command)', ->
    it 'raises an error if any of the mandatory fields are missing', ->
      assert.raises 'name', -> command.register {}
      assert.raises 'description', -> command.register name: 'foo'
      assert.raises 'handler', -> command.register name: 'foo', description: 'do'

  it '.names() returns a list of all command names', ->
    command.register cmd
    assert.includes command.names!, 'foo'

  it '.<name> allows direct indexing of commands', ->
    command.register cmd
    assert.equal command.foo.handler, cmd.handler

  it '.get(name) returns the command with the specified name', ->
    command.register cmd
    assert.equal command.get('foo').handler, cmd.handler

  it 'allows a registered command to be invoked directly', ->
    cmd.handler = (num) -> num * 2
    command.register cmd
    assert.equal command.foo(2), 4

  describe '.alias(target, name)', ->
    it 'raises an error if target does not exist', ->
      assert.raises 'exist', -> command.alias 'nothing', 'something'

    it 'allows for multiple names for the same command', ->
      command.register cmd
      command.alias 'foo', 'bar'
      assert.equal 'foo', command.bar.alias_for
      assert.includes command.names!, 'bar'

  it '.unregister(command) removes the command and any aliases', ->
    command.register cmd
    command.alias 'foo', 'bar'
    command.unregister 'foo'

    assert.is_nil command.foo
    assert.is_nil command.bar
    assert.same command.names!, {}

  context 'when command name is a non-lua identifier', ->
    before_each -> cmd.name = 'foo-cmd:bar'

    it 'register() adds accessible aliases for the direct indexing', ->
      command.register cmd
      assert.equal command['foo-cmd:bar'].handler, cmd.handler
      assert.equal command.foo_cmd_bar.handler, cmd.handler

    it 'the accessible alias is not part of names()', ->
      command.register cmd
      assert.same command.names!, { 'foo-cmd:bar' }

    it 'unregister() removes the accessible name as well', ->
      command.register cmd
      command.unregister 'foo-cmd:bar'
      assert.is_nil command.foo_cmd_bar

  describe '.run(cmd_string)', ->
    local input

    before_each ->
      inputs.register {
        name: 'test_input',
        description: 'command spec input',
        factory: ->
          input = {
            complete: -> 'completions'
            should_complete: -> 'perhaps'
            close_on_cancel: -> true
            value_for: -> 123
            on_completed: spy.new -> nil
            go_back: spy.new -> nil
            on_cancelled: spy.new -> nil
          }
          input
      }

    after_each -> inputs.unregister 'test_input'

    context 'when <cmd_string> is empty or missing', ->
      it 'invokes howl.app.window.readline with a ":" prompt', ->
        command.run!
        assert.spy(readline.read).was_called!
        assert.equals ':', readline.prompt

    context 'when <cmd_string> is given', ->
      context 'and it matches a simple command without parameters', ->
        it 'that command is invoked direcly', ->
          command.register cmd
          command.run cmd.name
          assert.spy(cmd.handler).was_called

      context 'when it specifies a command with parameters', ->
        it 'invokes howl.app.window.readline', ->
          cmd.input = 'test_input'
          command.register cmd
          command.run cmd.name
          assert.spy(cmd.handler).was_not_called(1)
          assert.spy(readline.read).was_called(1)
          assert.equals "#{cmd.name} ", readline.text

      context 'when it specifies a unknown command', ->
        it 'invokes readline.read with the text set to the given string', ->
          command.run 'what-the-heck now'
          assert.spy(readline.read).was_called(1)
          assert.equals 'what-the-heck now', readline.text

    it 'accepts function values as inputs"', ->
      input = value_for: -> 'yay'
      cmd.input = spy.new -> input
      command.register cmd
      command.run cmd.name
      assert.spy(cmd.input).was.called 1

    context 'interacting with readline', ->
      local cmd_input, readline, handler, co, return_value

      run = (...) ->
        f = coroutine.wrap (...) -> command.run ...
        return_value = f ...

      fake_return = (...) ->
        coroutine.resume co, ...

      before_each ->
        readline = read: (prompt, i) =>
          co = coroutine.running!
          cmd_input = i
          @prompt = prompt
          @text = ''
          coroutine.yield!

        app.window = :readline

        handler = spy.new -> nil

        command.register {
          name: 'p_cmd',
          description: 'desc',
          :handler
          input: 'test_input'
        }

      after_each -> command.unregister name for name in *command.names!

      context 'when entering a command', ->
        it 'should_complete(..) returns false', ->
          run!
          assert.is_false cmd_input\should_complete '', readline

        it 'complete(..) returns a list of command names, key bindings, and descriptions', ->
          keymap.ctrl_shift_p = 'p_cmd'
          run!
          completions = cmd_input\complete '', readline
          assert.same completions, { { 'p_cmd', 'ctrl_shift_p', 'desc' } }

      context 'when entering command arguments', ->
        it 'delegates all input methods to the current corresponding input', ->
          run!
          cmd_input\update 'p_cmd first', readline
          assert.not_nil input
          assert.equal cmd_input\complete(readline.text, readline), input.complete!
          assert.equal cmd_input\should_complete(readline.text, readline), input.should_complete!
          assert.equal cmd_input\close_on_cancel(readline.text, readline), input.close_on_cancel!

          cmd_input\on_completed(readline.text, readline)
          assert.spy(input.on_completed).was_called 1

          cmd_input\go_back(readline)
          assert.spy(input.go_back).was_called 1

          cmd_input\on_cancelled(readline)
          assert.spy(input.on_cancelled).was_called 1

        it 'updates the readline prompt to include the command name when it is complete', ->
          run!
          cmd_input\update 'p_cmd first', readline
          assert.match readline.prompt, 'p_cmd $'

        it 'runs the command when the user submits', ->
          run!
          readline.text = 'p_cmd first'
          cmd_input\update readline.text, readline
          fake_return 'first'
          assert.spy(handler).was_called_with input\value_for!

      context 'when the user submits an unknown command', ->
        it 'the on_submit callback returns false to keep readline open', ->
          run!
          assert.is_false cmd_input\on_submit 'unknowncommand', readline

      context 'when the user submits a known command but with too few arguments', ->
        it 'the on_submit callback returns false to keep readline open', ->
          run!
          assert.is_false cmd_input\on_submit 'p_cmd', readline

        it 'the command is added to the readline prompt', ->
          run!
          readline.text = 'p_cmd'
          cmd_input\update readline.text, readline
          cmd_input\on_submit 'p_cmd', readline
          assert.match readline.prompt, 'p_cmd $'
