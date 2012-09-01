import command, inputs, config from lunar
import Spy from lunar.spec

describe 'command', ->
  cmd = nil

  before -> cmd = name: 'foo', description: 'desc', handler: -> true
  after -> command.unregister 'foo'

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

  describe '.run()', ->
    it 'invokes _G.window.readline with a ":" prompt', ->
      readline = Spy as_null_object: true
      _G.window = :readline
      command.run!
      assert_true readline.read.called
      _, prompt = unpack readline.read.called_with
      assert_equal prompt, ':'

    context 'interacting with readline', ->
      input = nil
      callback = nil
      readline = nil
      first_input = nil
      second_input = nil

      before ->
        readline = read: (prompt, i, c) =>
          input = i
          callback = c
          @prompt = prompt
          @text = ''
        _G.window = :readline

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

        command.register {
          name: 'p_cmd',
          description: 'desc',
          handler: -> true
          inputs: { 'test_first', 'test_second' }
        }

      after ->
        inputs.unregister 'test_first'
        inputs.unregister 'test_second'
        command.unregister name for name in *command.names!

      context 'when entering a command', ->
        it 'should_complete(..) returns false', ->
          command.run!
          assert_false input\should_complete '', readline

        it 'complete(..) returns a list of command names and descriptions', ->
          command.run!
          completions = input\complete '', readline
          assert_table_equal completions, { { 'p_cmd', 'desc' } }

        it 'value_for(..) returns the value as is', ->
          assert_equal input\value_for(123), 123

      context 'when entering command arguments', ->
        it 'delegates all input methods to the current corresponding input', ->
          command.run!
          input\update 'p_cmd first', readline
          assert_not_nil first_input
          assert_equal input\complete(readline.text, readline), first_input.complete!
          assert_equal input\should_complete(readline.text, readline), first_input.should_complete!
          assert_equal input\value_for(readline.text), first_input.value_for!

          input\on_completed(readline.text, readline)
          assert_true first_input.on_completed.called

          input\go_back(readline)
          assert_true first_input.go_back.called

          readline.text ..= ' second'
          input\update readline.text, readline
          assert_not_nil second_input
          assert_equal input\complete(readline.text, readline), second_input.complete!
          assert_equal input\should_complete(readline.text, readline), second_input.should_complete!
          assert_equal input\value_for(readline.text), second_input.value_for!

          input\on_completed(readline.text, readline)
          assert_true second_input.on_completed.called

          input\go_back(readline)
          assert_true second_input.go_back.called

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
