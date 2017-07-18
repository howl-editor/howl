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

  it 'calling .<name>(args) invokes command, passing arguments', ->
    command.register cmd
    command.foo('arg1', 'arg2')
    assert.spy(cmd.handler).was_called 1
    assert.spy(cmd.handler).was_called_with 'arg1', 'arg2'

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

    it 'register() adds accessible aliases', ->
      command.register cmd
      assert.not_nil command.foo_cmd_bar

    it 'the accessible alias is not part of names()', ->
      command.register cmd
      assert.same command.names!, { 'foo-cmd:bar' }

    it 'calling .<accessible_name>(args) invokes command, passing arguments', ->
      command.register cmd
      dispatch.launch -> command.foo_cmd_bar('arg1', 'arg2')
      assert.spy(cmd.handler).was_called 1
      assert.spy(cmd.handler).was_called_with 'arg1', 'arg2'

    it 'unregister() removes the accessible name as well', ->
      command.register cmd
      command.unregister 'foo-cmd:bar'
      assert.is_nil command.foo_cmd_bar

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

        context 'and the command specifies an input function', ->
          before_each ->
            cmd =
              name: 'with-input'
              description: 'test'
              input: spy.new -> 'input-result1', 'input-result2'
              handler: spy.new ->
            command.register cmd

          it 'calls the command input function, passing through extra args', ->
            run cmd.name, 'arg1', 'arg2'
            assert.spy(cmd.input).was_called 1
            assert.spy(cmd.input).was_called_with 'arg1', 'arg2'

          it 'passes the result of the input function into the handler', ->
            run cmd.name
            assert.spy(cmd.handler).was_called 1
            assert.spy(cmd.handler).was_called_with 'input-result1', 'input-result2'

          it 'does not call handler if input function returns nil', ->
            cmd = {
              name: 'cancelled-input'
              description: 'test'
              input: ->
              handler: spy.new ->
            }
            command.register cmd
            run cmd.name
            assert.spy(cmd.handler).was_called 0

          it 'sets spillover to any text arguments before invoking the input', ->
            local spillover
            command.register
              name: 'with-input'
              description: 'test'
              input: -> spillover = app.window.command_line\pop_spillover!
              handler: ->
            run 'with-input hello cmd'
            assert.equal 'hello cmd', spillover

          it 'displays the ":<cmd_string> " in the command line during input', ->
            local prompt
            cmd = {
              name: 'getp'
              description: 'desc'
              input: -> prompt = app.window.command_line.command_widget.text
              handler: ->
            }
            command.register cmd
            run 'getp'
            assert.equals ':'..cmd.name..' ', prompt

        context 'and the command does not specify an input function', ->
          it 'calls the command handler, passing through extra args', ->
            cmd = {
              name: 'without-input'
              description: 'test'
              handler: spy.new ->
            }
            command.register cmd
            run cmd.name, 'arg1', 'arg2'
            assert.spy(cmd.handler).was_called 1
            assert.spy(cmd.handler).was_called_with 'arg1', 'arg2'

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

      context 'when it specifies a unknown command', ->
        it 'displays the <cmd_string> in the commandline text', ->
          run 'what-the-heck now'
          assert.equals 'what-the-heck now', app.window.command_line.text

