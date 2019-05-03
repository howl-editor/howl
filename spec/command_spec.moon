-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, command, dispatch from howl
import Window from howl.ui

describe 'command', ->
  local cmd
  run = (...) ->
    f = coroutine.wrap (...) -> command.run ...
    f ...

  before_each ->
    app.window = Window!
    cmd = name: 'test-foo', description: 'desc', handler: spy.new -> 'foo-result'

  after_each ->
    app.window = nil
    command.unregister name for name in *command.names! when name\find 'test-'

  describe '.register(command)', ->
    it 'raises an error if any of the mandatory fields are missing', ->
      assert.raises 'name', -> command.register {}
      assert.raises 'description', -> command.register name: 'test-foo'
      assert.raises 'handler', -> command.register name: 'test-foo', description: 'do'
      assert.raises 'factory', -> command.register name: 'test-foo', description: 'do'

  it '.names() returns a list of all command names', ->
    command.register cmd
    assert.includes command.names!, 'test-foo'

  it '.get(name) returns the command with the specified name', ->
    command.register cmd
    assert.equal command.get('test-foo').handler, cmd.handler

  it 'calling .<name>(args) invokes command, passing arguments', ->
    command.register cmd
    command.test_foo('arg1', 'arg2')
    assert.spy(cmd.handler).was_called 1
    assert.spy(cmd.handler).was_called_with 'arg1', 'arg2'

  describe '.alias(target, name)', ->
    it 'raises an error if target does not exist', ->
      assert.raises 'exist', -> command.alias 'nothing', 'something'

    it 'allows for multiple names for the same command', ->
      command.register cmd
      command.alias 'test-foo', 'bar'
      assert.equal 'test-foo', command.get('bar').alias_for
      assert.includes command.names!, 'bar'

  it '.unregister(command) removes the command and any aliases', ->
    command.register cmd
    command.alias 'test-foo', 'bar'
    command.unregister 'test-foo'

    assert.is_nil command.test_foo
    assert.is_nil command.bar
    assert.not_includes command.names!, 'test-foo'
    assert.not_includes command.names!, 'bar'

  context 'when command name is a non-lua identifier', ->
    before_each -> cmd.name = 'test-foo:bar'

    it 'register() adds accessible aliases', ->
      command.register cmd
      assert.not_nil command.test_foo_bar

    it 'the accessible alias is not part of names()', ->
      command.register cmd
      assert.includes command.names!, 'test-foo:bar'
      assert.not_includes command.names!, 'test_foo_bar'

    it 'calling .<accessible_name>(args) invokes command, passing arguments', ->
      command.register cmd
      dispatch.launch -> command.test_foo_bar('arg1', 'arg2')
      assert.spy(cmd.handler).was_called 1
      assert.spy(cmd.handler).was_called_with 'arg1', 'arg2'

    it 'unregister() removes the accessible name as well', ->
      command.register cmd
      command.unregister 'test-foo:bar'
      assert.is_nil command.foo_cmd_bar

  describe '.run(cmd_string)', ->
    context 'when <cmd_string> is empty or missing', ->
      it 'displays the commandline with a ":" prompt', ->
        run!
        assert.equals ':', app.window.command_panel.active_command_line.prompt

    context 'when <cmd_string> is given', ->
      context 'and it matches a command with no input', ->
        it 'that command is invoked', ->
          command.register cmd
          run cmd.name
          assert.spy(cmd.handler).was_called 1

      context 'and the command specifies an input function', ->
        before_each ->
          cmd =
            name: 'test-input'
            description: 'test'
            input: spy.new -> 'input-result1', 'input-result2'
            handler: spy.new ->
          command.register cmd

        it 'calls the command input function', ->
          run cmd.name, 'arg1', 'arg2'
          assert.spy(cmd.input).was_called 1

        it 'passes the result of the input function into the handler', ->
          run cmd.name
          assert.spy(cmd.handler).was_called 1
          assert.spy(cmd.handler).was_called_with 'input-result1', 'input-result2'

        it 'does not call handler if input function returns nil', ->
          cmd = {
            name: 'test-cancelled-input'
            description: 'test'
            input: ->
            handler: spy.new ->
          }
          command.register cmd
          run cmd.name
          assert.spy(cmd.handler).was_called 0

        it 'passes any text as opts.text when invoking the input function', ->
          local text
          command.register
            name: 'test-input'
            description: 'test'
            input: (opts)-> text = opts.text
            handler: ->
          run 'test-input hello cmd'
          assert.equal 'hello cmd', text

        it 'passes ":<cmd_string> " as opts.prompt when invoking the input function', ->
          local prompt
          cmd = {
            name: 'test-getp'
            description: 'desc'
            input: (opts) -> prompt = opts.prompt
            handler: ->
          }
          command.register cmd
          run 'test-getp'
          assert.equals ':'..cmd.name..' ', prompt

      context 'and the command does not specify an input function', ->
        it 'calls the command handler', ->
          cmd = {
            name: 'test-without-input'
            description: 'test'
            handler: spy.new ->
          }
          command.register cmd
          run cmd.name
          assert.spy(cmd.handler).was_called 1

      context 'and it matches an alias', ->
        it 'the aliased command is invoked', ->
          command.register cmd
          command.alias cmd.name, 'aliascmd'
          run 'aliascmd'
          assert.spy(cmd.handler).was_called 1

      context 'and it contains <non-interactive-command>space<args>', ->
        before_each ->
          log.clear!
          command.register cmd

        it 'logs an error', ->
          run cmd.name .. ' args'
          assert.not_nil log.last_error

      context 'and it contains <invalid-command>space<args>', ->
        it 'logs an error', ->
          run 'no-such-command hello cmd'
          assert.not_nil log.last_error

        it 'the command line contains the passed text', ->
          run 'no-such-command hello cmd'
          assert.equals 'no-such-command hello cmd', howl.app.window.command_panel.active_command_line.text
