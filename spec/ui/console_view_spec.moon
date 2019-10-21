-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app from howl
import ConsoleView, NotificationWidget from howl.ui

describe 'ConsoleView', ->
  local command_line, console, list_widget, console_view, command_line_result, command_line_error

  list_widget_items = -> list_widget.list._items
  keypress = (keystroke) -> console_view.keymap[keystroke](console_view) if console_view.keymap[keystroke]
  keypress_binding_for = (cmd) -> console_view.keymap.binding_for[cmd] console_view
  set_text = (text) ->
    command_line.text = text
    console_view\on_text_changed text

  before_each ->
    app.editor = {
      preview: spy.new ->
      cancel_preview: spy.new ->
    }
    command_line_result = '<finish-not-called>'
    command_line_error = '<no-error>'
    command_line =
      add_widget: spy.new (name, w) => list_widget = w if name == 'completer'
      notification: NotificationWidget!
      finish: (result) => command_line_result = result
    command_line.notification.error = (msg) => command_line_error = msg

    console = {
      display_prompt: ->
    }


  context 'on initialization', ->
    it 'calls add_widget on the passed command line, adding a list widget', ->
      e = ConsoleView console
      e\init command_line, max_height: 100
      assert.spy(command_line.add_widget).is_called 1
      assert.same "ListWidget", typeof(list_widget)

  context 'after initialization', ->
    before_each ->
      console_view = ConsoleView console
      console_view\init command_line, max_height: 100

    context 'updating text', ->
      it 'calls parse(text) on the console object for text updates', ->
        console.parse = spy.new ->
        set_text 'hello'
        assert.spy(console.parse).was_called_with console, 'hello'

        console.parse\clear!

        set_text 'new'
        assert.spy(console.parse).was_called_with console, 'new'

      it 'refreshes prompt whenever text is changed', ->
        prompt = 'first>'
        console.display_prompt = spy.new -> prompt
        console.parse = spy.new ->
        set_text 'hello'
        assert.spy(console.display_prompt).was_called 1

        console.display_prompt\clear!
        console.parse\clear!
        assert.same 'first>', command_line.prompt

        prompt = 'second>'
        set_text 'new'
        assert.spy(console.display_prompt).was_called 1
        assert.same 'second>', command_line.prompt

      it 'finishes with result when parse returns a result', ->
        console.parse = -> result: 'result'
        set_text 'hello'
        assert.same 'result', command_line_result

      it 'displays error when parse returns an error', ->
        console.parse = -> error: 'problem'
        set_text 'hello'
        assert.same '<finish-not-called>', command_line_result
        assert.same 'problem', command_line_error

    context 'keypresses', ->
      context 'tab', ->
        it 'displays completion list when complete() returns completions', ->
          console.complete = -> completions: {'a', 'b', 'c'}
          set_text ''
          keypress 'tab'
          assert.is_true list_widget.showing

          assert.same {'a', 'b', 'c'}, list_widget_items!

        it 'completions may contains multiple columns', ->
          console.complete = -> completions: {{'a', 'a2'}, {'b', 'b2'}, {'c', 'c2'}}
          set_text ''
          keypress 'tab'
          assert.is_true list_widget.showing

          assert.same {{'a', 'a2'}, {'b', 'b2'}, {'c', 'c2'}}, list_widget_items!


      context 'enter', ->
        it 'calls run(text) on console, finishing when result present', ->
          console.run = spy.new -> result: 'done'
          set_text 'cmd'
          keypress 'enter'
          assert.spy(console.run).was_called_with console, 'cmd'

          assert.same 'done', command_line_result

        it 'calls select(selection) on console when list is displayed', ->
          selection = '<no-selection>'
          text = '<no-text>'
          console.select = spy.new (t, s) =>
            text = t
            selection = s
            return result: 'done'

          console.complete = -> completions: {'a', 'b', 'c'}
          set_text 'hello'
          keypress 'tab'
          assert.is_true list_widget.showing

          keypress 'enter'
          assert.spy(console.select).was_called 1
          assert.same 'hello', text
          assert.same 'a', selection

      context 'escape', ->
        it 'finishes with empty result when list is hidden', ->
          set_text 'hello'
          assert.same '<finish-not-called>', command_line_result

          keypress 'escape'
          assert.is_nil command_line_result

        it 'hides list when it is showing, does not finish', ->
          console.complete = -> completions: {'a', 'b', 'c'}
          set_text ''
          keypress 'tab'
          assert.is_true list_widget.showing

          keypress 'escape'
          assert.same '<finish-not-called>', command_line_result
          assert.is_false list_widget.showing

      context 'backspace', ->
        it 'calls back() on console if no text', ->
          console.back = spy.new ->
          set_text 'hello'
          keypress 'backspace'
          assert.spy(console.back).was_not_called!

          set_text ''
          keypress 'backspace'
          assert.spy(console.back).was_called 1

      context 'history', ->
        it 'pressing up calls get_history on console and displays history items reversed', ->
          console.get_history = spy.new -> {'hist-c', 'hist-b', 'hist-a'}
          set_text ''
          assert.is_false list_widget.showing
          keypress_binding_for 'cursor-up'
          assert.spy(console.get_history).was_called 1
          assert.is_true list_widget.showing
          assert.same {'hist-a', 'hist-b', 'hist-c'}, list_widget_items!

        it 'pressing enter when history just sets the command text', ->
          console.get_history = spy.new -> {'hist-c', 'hist-b', 'hist-a'}
          set_text ''
          keypress_binding_for 'cursor-up'  -- invokes history
          keypress_binding_for 'cursor-up'  -- selects previous command (hist-b)
          keypress 'enter'
          assert.is_false list_widget.showing
          assert.same 'hist-b', command_line.text
