-- Copyright 2012-2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import CommandPanel from howl.ui
import Window from howl.ui

Gtk = require 'ljglibs.gtk'

describe 'CommandPanel', ->
  local command_panel
  run_in_coroutine = (f) ->
    wrapped = coroutine.wrap -> f!
    return wrapped!

  before_each ->
    command_panel = CommandPanel Window!

  after_each ->
    command_panel\cancel!

  describe 'run(def)', ->
    it 'errors if init field not in def', ->
      assert.raises 'init', -> command_panel\run {}

    it 'invokes init on def, passing in def, a CommandLine', ->
      local args
      def = init: spy.new (arg1, arg2) -> args = {arg1, arg2}
      run_in_coroutine -> command_panel\run def
      assert.spy(def.init).was_called 1
      assert.equal def, args[1]
      assert.same 'CommandLine', typeof(args[2])

    context "when no opts.text is set", ->
      it 'invokes on_text_changed on def, passing in ""', ->
        def = {
          init: spy.new ->
          on_text_changed: spy.new ->
        }
        run_in_coroutine -> command_panel\run def
        assert.spy(def.on_text_changed).was_called_with def, ''

    context "when opts.text is set", ->
      it 'invokes on_text_changed on def, passing in opts.text', ->
        def = {
          init: spy.new ->
          on_text_changed: spy.new ->
        }
        run_in_coroutine -> command_panel\run def, text: 'initial'
        assert.spy(def.on_text_changed).was_called_with def, 'initial'

  context "cancel", ->
    it "cancels running command lines", ->
      result = '<unset>'
      run_in_coroutine -> result = command_panel\run {init: ->}
      command_panel\cancel!
      assert.is_nil result

    it "invokes on_close", ->
      def = {
        init: spy.new ->
        on_close: spy.new ->
      }
      run_in_coroutine -> command_panel\run def
      command_panel\cancel!
      assert.spy(def.on_close).was_called 1

  describe 'CommandLine', ->
    local command_line, text_widget, def
    result = '<unset>'

    before_each ->
      def = {
        init: (_, c) ->
          command_line = c
          text_widget = c.command_widget
      }
      run_in_coroutine -> result = command_panel\run def

    it 'finish(result) terminates the invocation, returning result', ->
      command_line\finish 'result'
      assert.same 'result', result

    it 'finishing calls on_close', ->
      def.on_close = spy.new ->
      command_line\finish 'result'
      assert.spy(def.on_close).was_called 1

    it '.prompt and .text set the text in the text widget', ->
      command_line.prompt = 'prompt>'
      assert.same 'prompt>', text_widget.text
      command_line.text = 'hello'
      assert.same 'prompt>hello', text_widget.text

      command_line.prompt = '[bye]'
      command_line.text = 'hello'
      assert.same '[bye]hello', text_widget.text
      command_line.text = ''
      assert.same '[bye]', text_widget.text

    it 'add_widget calls to_gobject and show on the added widget', ->
      widget = {
        to_gobject: spy.new -> Gtk.Box!
        show: spy.new ->
      }
      command_line\add_widget 'name', widget
      assert.spy(widget.to_gobject).was_called 1
      assert.spy(widget.show).was_called 1

    it 'changing the text invokes def.on_text_changed', ->
      def.on_text_changed = spy.new ->
      command_line.text = 'changed'
      assert.spy(def.on_text_changed).was_called 1
      assert.spy(def.on_text_changed).was_called_with def, 'changed'

    context 'recursively calling command_panel\\run', ->
      local def2, command_line2
      before_each ->
        def2 = {
        init: spy.new (_, c) ->
          command_line2 = c
        }
        run_in_coroutine -> result = command_panel\run def2

      it 'instantiates the new command line', ->
        assert.spy(def2.init).was_called 1

      it 'hides the existing command line', ->
        assert.is_true command_line.is_hidden
        assert.is_false command_line2.is_hidden

      it 'changing the text invokes the on_text_changed on the inner command_line', ->
        def.on_text_changed = spy.new ->
        def2.on_text_changed = spy.new ->

        command_line2.text = 'changed'
        assert.spy(def2.on_text_changed).was_called 1
        assert.spy(def2.on_text_changed).was_called_with def2, 'changed'
        assert.spy(def.on_text_changed).was_not_called!

      it 'closing the inner command line unhides the outer command line', ->
        command_line2\finish 'result'
        assert.is_false command_line2.is_open
        assert.is_false command_line.is_hidden
        assert.is_true command_line.is_open

