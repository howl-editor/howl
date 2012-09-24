import command, inputs, config from lunar
import Spy from lunar.spec

describe 'command', ->
  cmd = nil

  before -> cmd = name: 'foo', description: 'desc', handler: -> true
  after -> command.unregister name for name in *command.names!

  describe '.register(command)', ->
    it 'raises an error if any of the mandatory fields are missing', ->
      assert_raises 'name', -> command.register {}
      assert_raises 'description', -> command.register name: 'foo'
      assert_raises 'handler', -> command.register name: 'foo', description: 'do'

  it '.names() returns a list of all command names', ->
    command.register cmd
    assert_table_equal command.names!, { 'foo' }

  it '.<name> allows direct indexing of commands', ->
    command.register cmd
    assert_equal command.foo.handler, cmd.handler

  it '.get(name) returns the command with the specified name', ->
    command.register cmd
    assert_equal command.get('foo').handler, cmd.handler

  it 'allows a registered command to be invoked directly', ->
    cmd.handler = (num) -> num * 2
    command.register cmd
    assert_equal command.foo(2), 4

  describe '.alias(target, name)', ->
    it 'raises an error if target does not exist', ->
      assert_raises 'exist', -> command.alias 'nothing', 'something'

    it 'allows for multiple names for the same command', ->
      command.register cmd
      command.alias 'foo', 'bar'
      assert_equal command.bar, command.foo
      assert_table_equal command.names!, { 'foo', 'bar' }

  it '.unregister(command) removes the command and any aliases', ->
    command.register cmd
    command.alias 'foo', 'bar'
    command.unregister 'foo'

    assert_nil command.foo
    assert_nil command.bar
    assert_table_equal command.names!, {}

  context 'when command name is a non-lua identifier', ->
    before -> cmd.name = 'foo-cmd:bar'

    it 'register() adds accessible aliases for the direct indexing', ->
      command.register cmd
      assert_equal command['foo-cmd:bar'].handler, cmd.handler
      assert_equal command.foo_cmd_bar.handler, cmd.handler

    it 'the accessible alias is not part of names()', ->
      command.register cmd
      assert_table_equal command.names!, { 'foo-cmd:bar' }

    it 'unregister() removes the accessible name as well', ->
      command.register cmd
      command.unregister 'foo-cmd:bar'
      assert_nil command.foo_cmd_bar

  describe '.run(cmd_string)', ->
    first_input = nil
    second_input = nil

    before ->
      inputs.register 'test_first', ->
        first_input = {
          complete: -> 'completions'
          should_complete: -> 'perhaps'
          value_for: -> 123
          on_completed: Spy!
          go_back: Spy!
        }
        first_input

      inputs.register 'test_second', ->
        second_input = {
          complete: -> 'other completions'
          should_complete: -> 'oh yes'
          value_for: -> 321
          on_completed: Spy!
          go_back: Spy!
        }
        second_input

    after ->
      inputs.unregister 'test_first'
      inputs.unregister 'test_second'
      _G.window = nil

    context 'when <cmd_string> is empty or missing', ->
      it 'invokes _G.window.readline with a ":" prompt', ->
        readline = Spy as_null_object: true
        _G.window = :readline
        command.run!
        assert_true readline.read.called
        _, prompt = unpack readline.read.called_with
        assert_equal prompt, ':'

    context 'when <cmd_string> is given', ->
      context 'and it matches a simple command without parameters', ->
        it 'that command is invoked direcly', ->
          cmd.handler = Spy!
          command.register cmd
          command.run cmd.name
          assert_true cmd.handler.called

      context 'when it specifies a command with all required parameters', ->
        it 'that command is invoked directly with converted values', ->
          cmd.handler = Spy!
          cmd.inputs = { 'test_first' }
          command.register cmd
          command.run cmd.name .. ' foo'
          assert_table_equal cmd.handler.called_with, { first_input.value_for! }

      context 'when it specifies a command without all required parameters', ->
        it 'invokes _G.window.readline with the prompt set to the given string', ->
          readline = Spy as_null_object: true
          _G.window = :readline
          cmd.inputs = { 'test_first', 'test_second' }
          command.register cmd
          command.run cmd.name .. ' arg'
          assert_true readline.read.called
          _, prompt = unpack readline.read.called_with
          assert_equal prompt, ':' .. cmd.name .. ' arg '

    context 'interacting with readline', ->
      input = nil
      callback = nil
      readline = nil
      handler = nil

      before ->
        readline = read: (prompt, i, c) =>
          input = i
          callback = c
          @prompt = prompt
          @text = ''
        _G.window = :readline

        handler = Spy!

        command.register {
          name: 'p_cmd',
          description: 'desc',
          :handler
          inputs: { 'test_first', 'test_second' }
        }

      after -> command.unregister name for name in *command.names!

      context 'when entering a command', ->
        it 'should_complete(..) returns false', ->
          command.run!
          assert_false input\should_complete '', readline

        it 'complete(..) returns a list of command names and descriptions', ->
          command.run!
          completions = input\complete '', readline
          assert_table_equal completions, { { 'p_cmd', 'desc' } }

      context 'when entering command arguments', ->
        it 'delegates all input methods to the current corresponding input', ->
          command.run!
          input\update 'p_cmd first', readline
          assert_not_nil first_input
          assert_equal input\complete(readline.text, readline), first_input.complete!
          assert_equal input\should_complete(readline.text, readline), first_input.should_complete!

          input\on_completed(readline.text, readline)
          assert_true first_input.on_completed.called

          input\go_back(readline)
          assert_true first_input.go_back.called

          readline.text ..= ' second'
          input\update readline.text, readline
          assert_not_nil second_input
          assert_equal input\complete(readline.text, readline), second_input.complete!
          assert_equal input\should_complete(readline.text, readline), second_input.should_complete!

          input\on_completed(readline.text, readline)
          assert_true second_input.on_completed.called

          input\go_back(readline)
          assert_true second_input.go_back.called

        it 'updates the readline prompt to include arguments when they are finished', ->
          command.run!
          input\update 'p_cmd first', readline
          assert_match 'p_cmd $', readline.prompt
          readline.text ..= ' second'
          input\update readline.text, readline
          assert_match 'p_cmd first $', readline.prompt

        it 'runs the command when the user submits', ->
          command.run!
          readline.text = 'p_cmd first final'
          input\update readline.text, readline
          readline.text = 'final'
          assert_true callback readline.text, readline
          assert_true handler.called

      context 'when the user submits an unknown command', ->
        it 'the callback returns false to keep readline open', ->
          command.run!
          assert_false callback 'unknowncommand', readline

      context 'when the user submits a known command but with too few arguments', ->
        it 'the callback returns false to keep readline open', ->
          command.run!
          assert_false callback 'p_cmd', readline

        it 'the callback adds command to the readline prompt', ->
          command.run!
          readline.text = 'p_cmd'
          input\update readline.text, readline
          callback 'p_cmd', readline
          assert_match 'p_cmd $', readline.prompt
