-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, command, dispatch, interact, config, keymap from howl
import Window from howl.ui

describe 'command', ->
  local cmd
  run = (...) ->
    f = coroutine.wrap (...) -> command.run ...
    f ...

  before_each ->
    app.window = Window!
    cmd = name: 'foo', description: 'desc', handler: spy.new -> 'foo-result'

  after_each ->
    app.window = nil
    command.unregister name for name in *command.names!

  describe '.register(command)', ->
    it 'raises an error if any of the mandatory fields are missing', ->
      assert.raises 'name', -> command.register {}
      assert.raises 'description', -> command.register name: 'foo'
      assert.raises 'handler', -> command.register name: 'foo', description: 'do'
      assert.raises 'factory', -> command.register name: 'foo', description: 'do'

  it '.names() returns a list of all command names', ->
    command.register cmd
    assert.includes command.names!, 'foo'

  it '.get(name) returns the command with the specified name', ->
    command.register cmd
    assert.equal command.get('foo').handler, cmd.handler

  describe '.alias(target, name)', ->
    it 'raises an error if target does not exist', ->
      assert.raises 'exist', -> command.alias 'nothing', 'something'

    it 'allows for multiple names for the same command', ->
      command.register cmd
      command.alias 'foo', 'bar'
      assert.equal 'foo', command.get('bar').alias_for
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
      assert.equal command.get('foo-cmd:bar').handler, cmd.handler

    it 'the accessible alias is not part of names()', ->
      command.register cmd
      assert.same command.names!, { 'foo-cmd:bar' }

    it 'unregister() removes the accessible name as well', ->
      command.register cmd
      command.unregister 'foo-cmd:bar'
      assert.is_nil command.get('foo_cmd_bar')

  describe '.run(cmd_string)', ->
    context 'when <cmd_string> is empty or missing', ->
      it 'displays the commandline with a ":" prompt', ->
        run!
        assert.equals ':', app.window.command_line.prompt

    context 'when <cmd_string> is given', ->
      context 'and it matches a command', ->
        it 'that command is invoked', ->
          command.register cmd
          run cmd.name
          assert.spy(cmd.handler).was_called 1

        it 'returns the result of running the command', ->
          command.register cmd
          result = run cmd.name
          assert.equals 'foo-result', result

        it 'displays the ":<cmd_string> " in the commandline', ->
          local prompt
          cmd = name: 'getp', description: 'desc', handler: -> prompt = app.window.command_line.command_widget.text
          command.register cmd
          run 'getp'
          assert.equals ':'..cmd.name..' ', prompt

      context 'and it matches an alias', ->
        it 'the aliased command is invoked', ->
          command.register cmd
          command.alias cmd.name, 'aliascmd'
          run 'aliascmd'
          assert.spy(cmd.handler).was_called 1

      context 'and it contains <interactive-command>space<args>', ->
        it 'the command is invoked with the args passed in spillover', ->
          spy_handler = spy.new -> app.window.command_line\pop_spillover!
          command.register
            name: 'foo-interactive'
            description: 'test'
            interactive: true
            handler: spy_handler
          result = run 'foo-interactive hello cmd'
          assert.spy(spy_handler).was_called 1
          assert.equal 'hello cmd', result

      context 'and it contains <non-interactive-command>space<args>', ->
        before_each ->
          log.clear!
          command.register cmd

        it 'logs an error', ->
          run cmd.name .. ' args'
          assert.not_nil log.last_error

        it 'the command line contains the command name', ->
          run cmd.name .. ' args'
          assert.equals cmd.name, app.window.command_line.text

      context 'and it contains <invalid-command>space<args>', ->
        it 'logs an error', ->
          run 'no-such-command hello cmd'
          assert.not_nil log.last_error

        it 'the command line contains the passed text', ->
          run 'no-such-command hello cmd'
          assert.equals 'no-such-command hello cmd', app.window.command_line.text

      context 'when directory: is provided', ->
        it 'sets command_line.directory for invoked command', ->
          local dir
          command.register
            name: 'testcmd'
            description: 'test'
            handler: -> dir = app.window.command_line.directory
          run 'testcmd', directory: howl.io.File('/a/b/c')
          assert.same '/a/b/c', tostring dir

      context 'and it matches a factory based command', ->
        it 'that command is invoked', ->
          runf = spy.new ->
          command.register
            name: 'testcmdfactory'
            description: 'test'
            factory: -> { run: runf }
          run 'testcmdfactory'
          assert.spy(runf).was_called 1

        context 'when submit: true is provided', ->
          it 'invokes keymap.enter on the command', ->
            keymap_enter = spy.new ->
            command.register
              name: 'testcmd2'
              description: 'test'
              factory: -> {
                run: ->
                keymap: enter: keymap_enter
              }
            run 'testcmd2', submit: true
            assert.spy(keymap_enter).was_called 1


      context 'when it specifies a unknown command', ->
        it 'displays the <cmd_string> in the commandline text', ->
          run 'what-the-heck now'
          assert.equals 'what-the-heck now', app.window.command_line.text

