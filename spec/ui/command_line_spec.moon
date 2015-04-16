-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, dispatch, interact from howl
import Window from howl.ui

describe 'CommandLine', ->
  local command_line, run_as_handler

  run_in_coroutine = (f) ->
    wrapped = coroutine.wrap -> f!
    return wrapped!

  before_each ->
    app.window = Window!
    command_line = app.window.command_line
    run_as_handler = (f) ->
      command_line\run
        name: 'within-activity'
        handler: -> f!

  after_each ->
    ok, result = pcall -> app.window.command_line\abort_all!
    if not ok
      print result
    run_as_handler = nil
    command_line = nil
    app.window = nil

  describe 'command_line', ->
    describe '\\run(activity_spec)', ->
      it 'errors if handler or factory field not in spec', ->
        f = -> command_line\run {}
        assert.has_error f, 'activity_spec requires "name" and one of "handler" or "factory" fields'

      describe 'for activity with handler', ->
        it 'calls activity handler', ->
          handler = spy.new ->
          command_line\run
            name: 'run-activity'
            handler: handler
          assert.spy(handler).was_called 1

        it 'passes any extra args to handler', ->
          handler = spy.new ->
          aspec =
            name: 'run-activity'
            handler: handler
          command_line\run aspec, 'a1', 'a2', 'a3'
          assert.spy(handler).was_called_with 'a1', 'a2', 'a3'

        it 'returns result of handler', ->
          result = command_line\run
            name: 'run-activity'
            handler: -> return 'r1'
          assert.equal 'r1', result

      describe 'for activity with factory', ->
        it 'instantiates facory, calls run method', ->
          handler = spy.new ->
          run_in_coroutine ->
            command_line\run
              name: 'run-factory'
              factory: ->
                run: handler
          assert.spy(handler).was_called 1

        it 'passes instantiated object, finish function, extra args to run', ->
          local args
          obj = run: (...) ->
            args = {...}

          aspec =
            name: 'run-factory'
            factory: -> obj
          run_in_coroutine ->
            command_line\run aspec, 'a1', 'a2'

          assert.equal args[1], obj
          assert.equal 'function', type(args[2])
          assert.equal 'a1', args[3]
          assert.equal 'a2', args[4]

        it 'returns result passed in finish function', ->
          local result
          run_in_coroutine ->
            result = command_line\run
              name: 'run-factory'
              factory: ->
                run: (finish) => finish('r2')
          assert.equal 'r2', result

    describe '\\run_after_finish(f)', ->
      it 'calls f! immediately after the current activity stack exits', ->
        nextf = spy.new ->
        command_line\run
          name: 'run-activity'
          handler: ->
            command_line\run_after_finish nextf
        assert.spy(nextf).was_called 1

    describe '.text', ->
      it 'cannot be set when no running activity', ->
        f = -> command_line.text = 'hello'
        assert.has_error f, 'Cannot set text - no running activity'

      it 'returns nil when no running activity', ->
        assert.equals nil, command_line.text

      it 'updates the text displayed in the command_widget', ->
        run_as_handler ->
          command_line.text = 'hello'
          assert.equal 'hello', command_line.command_widget.text
          command_line.text = 'bye'
          assert.equal 'bye', command_line.command_widget.text

      it 'returns the text previously set', ->
        run_as_handler ->
          assert.equal command_line.text, ''
          command_line.text = 'hi'
          assert.equal 'hi', command_line.text

    describe '.prompt', ->
      it 'does not work when no running activity', ->
        f = -> command_line.prompt = 'hello'
        assert.has_error f, 'Cannot set prompt - no running activity'

      it 'updates the prompt displayed in the command_widget', ->
        run_as_handler ->
          command_line.prompt = 'hello'
          assert.equal 'hello', command_line.command_widget.text
          command_line.prompt = 'bye'
          assert.equal 'bye', command_line.command_widget.text

      it 'returns the prompt previously set', ->
        run_as_handler ->
          command_line.prompt = 'set'
          assert.equal 'set', command_line.prompt

    describe 'title', ->
      it 'is hidden by default', ->
        run_as_handler ->
          assert.equal false, command_line.header\to_gobject!.visible

      it 'is shown and updated by setting .title', ->
        run_as_handler ->
          command_line.title = 'Nice Title'
          assert.equal 'Nice Title', command_line.indic_title.label
          assert.equal true, command_line.header\to_gobject!.visible

      it 'is hidden by setting title to empty string', ->
        run_as_handler ->
          command_line.title = 'Nice Title'
          assert.equal true, command_line.header\to_gobject!.visible
          command_line.title = ''
          assert.equal false, command_line.header\to_gobject!.visible

      it 'is restored to the one set by the current interaction', ->
        run_as_handler ->
          command_line.title = 'Title 0'
          assert.equal 'Title 0', command_line.indic_title.label

          run_as_handler ->
            command_line.title = 'Title 1'
            assert.equal 'Title 1', command_line.indic_title.label

          assert.equal 'Title 0', command_line.indic_title.label

    describe 'when using both .prompt and .text', ->
      it 'the prompt is displayed before the text', ->
        run_as_handler ->
          command_line.prompt = 'prómpt:'
          command_line.text = 'téxt'
          assert.equal 'prómpt:téxt', command_line.command_widget.text

      it 'preserves text when updating prompt', ->
        run_as_handler ->
          command_line.prompt = 'héllo:'
          command_line.text = 'téxt'
          assert.equal 'héllo:téxt', command_line.command_widget.text
          command_line.prompt = 'hóla:'
          assert.equal 'hóla:téxt', command_line.command_widget.text

      it 'preserves prompt when updating téxt ', ->
        run_as_handler ->
          command_line.prompt = 'héllo:'
          command_line.text = 'téxt '
          assert.equal 'héllo:téxt ', command_line.command_widget.text
          command_line.text = 'hóla'
          assert.equal 'héllo:hóla', command_line.command_widget.text

      context 'clear()', ->
        it 'clears the text only, leaving prompt intact', ->
          run_as_handler ->
            command_line.prompt = 'héllo:'
            command_line.text = 'téxt'
            command_line\clear!
            assert.equal 'héllo:', command_line.command_widget.text

    describe 'when using nested interactions', ->
      it 'each interaction has independent prompt and text', ->
        run_as_handler ->
          command_line.prompt = 'outer:'
          command_line.text = '0'
          assert.equal 'outer:0', command_line.command_widget.text

          run_as_handler ->
            command_line.prompt = 'inner:'
            command_line.text = '1'
            assert.equal 'outer:0inner:1', command_line.command_widget.text
            command_line.prompt = 'later:'
            assert.equal 'outer:0later:1', command_line.command_widget.text

          assert.equal 'outer:0', command_line.command_widget.text

      it '.stack_depth returns number of running activities', ->
        depths = {}
        table.insert depths, command_line.stack_depth
        run_as_handler ->
          table.insert depths, command_line.stack_depth
          run_as_handler ->
            table.insert depths, command_line.stack_depth
            run_as_handler ->
              table.insert depths, command_line.stack_depth
            table.insert depths, command_line.stack_depth
          table.insert depths, command_line.stack_depth
        table.insert depths, command_line.stack_depth

        assert.same { 0, 1, 2, 3, 2, 1, 0 }, depths

      it '\\abort_all! cancels all running activities', ->
        depths = {}
        table.insert depths, command_line.stack_depth
        run_as_handler ->
          table.insert depths, command_line.stack_depth
          run_as_handler ->
            table.insert depths, command_line.stack_depth
            run_as_handler ->
              table.insert depths, command_line.stack_depth
              command_line\abort_all!
              table.insert depths, command_line.stack_depth

        assert.same { 0, 1, 2, 3, 0 }, depths

      it 'finishing any activity aborts all nested activities', ->
        depths = {}
        table.insert depths, command_line.stack_depth
        run_as_handler ->
          dispatch.launch ->
            table.insert depths, command_line.stack_depth
            p = dispatch.park 'command_line_test'
            dispatch.launch ->
              run_as_handler -> run_as_handler ->
                  table.insert depths, command_line.stack_depth
                  dispatch.resume p

            dispatch.wait p
            table.insert depths, command_line.stack_depth

        assert.same {0, 1, 3, 1}, depths

      it '\\clear_all! clears the entire command line and restores on exit', ->
        texts = {}
        run_as_handler ->
          command_line.prompt = 'outér:'
          command_line.text = '0'
          run_as_handler ->
            table.insert texts, command_line.command_widget.text
            command_line\clear_all!
            table.insert texts, command_line.command_widget.text
            command_line.prompt = 'innér:'
            command_line.text = '1'
            table.insert texts, command_line.command_widget.text
          table.insert texts, command_line.command_widget.text
        assert.same { 'outér:0', '', 'innér:1', 'outér:0' }, texts

