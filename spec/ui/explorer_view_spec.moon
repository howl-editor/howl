-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, Buffer from howl
import ExplorerView, NotificationWidget from howl.ui

describe 'ExplorerView', ->
  local command_line, explorer, list_widget, explorer_view

  list_widget_text = -> list_widget.text_widget.buffer.text
  list_widget_items = -> list_widget.list._items
  keypress = (keystroke) -> explorer_view.keymap[keystroke] explorer_view
  keypress_binding_for = (cmd) -> explorer_view.keymap.binding_for[cmd] explorer_view

  before_each ->
    app.editor = {
      preview: spy.new ->
      cancel_preview: spy.new ->
    }
    explorer = display_items: -> {}
    command_line =
      add_widget: spy.new (name, w) => list_widget = w if name == 'explore_list'
      notification: NotificationWidget!

  context 'on initialization', ->
    it 'calls add_widget on the passed command line, adding a list widget', ->
      e = ExplorerView path: {explorer}
      e\init command_line, max_height: 100
      assert.spy(command_line.add_widget).is_called 1
      assert.same "ListWidget", typeof(list_widget)

    it 'calls display_items() on the explorer object, and displays those items in the list', ->
      explorer.display_items = spy.new -> {'one', 'two', 'three'}

      e = ExplorerView path: {explorer}
      e\init command_line, max_height: 100
      e\on_text_changed ''

      assert.spy(explorer.display_items).is_called 1
      assert.same {'one', 'two', 'three'}, list_widget_items!

    it 'displays the provided prompt', ->
      e = ExplorerView path: {explorer}, prompt: 'hello>'
      e\init command_line, max_height: 100
      e\on_text_changed ''

      assert.same 'hello>', tostring command_line.prompt

  context 'displaying the items list', ->

    rebuild = (items, opts) ->
      -- draw an explorer returning (items, opts) from display_items()
      explorer.display_items = -> items, opts
      explorer_view = ExplorerView path: {explorer}
      explorer_view\init command_line, max_height: 100
      explorer_view\on_text_changed ''
      explorer_view\on_text_changed ''

    it 'displays a flat list of strings', ->
      rebuild {'one', 'two', 'three'}
      assert.is_true list_widget.showing
      assert.same 'one  \ntwo  \nthree\n', list_widget_text!

    it 'displays a list of tables as multiple columns', ->
      rebuild {{'one', 'abc'}, {'two', 'def'}, {'three', 'ghi'}}
      assert.is_true list_widget.showing
      assert.same 'one   abc\ntwo   def\nthree ghi\n', list_widget_text!

    it 'displays the result of calling display_row if present on the item', ->
      rebuild {{'one', 'abc'}, {'two', 'def', display_row: -> {'display', 'row'}}}
      assert.is_true list_widget.showing
      assert.same 'one     abc\ndisplay row\n', list_widget_text!

    context 'initial selection', ->
      it 'selects first item by default', ->
        rebuild {'a', 'b', 'c'}
        assert.same 'a', list_widget.list.selection
      it 'selects item specified as `selected_item` in opts returned by display_items', ->
        rebuild {'a', 'b', 'c'}, selected_item: 'b'

        assert.same 'b', list_widget.list.selection

    context 'when items provide a preview method', ->
      it 'calls the preview method when an item is selected', ->
        items = {
          {display_row: -> {'one'},
           preview: spy.new -> },
          {display_row: -> {'two'},
           preview: spy.new -> },
        }
        rebuild items
        assert.spy(items[1].preview).was_called 1
        assert.spy(app.editor.preview).was_not_called!

        assert.spy(items[2].preview).was_not_called!
        explorer_view\on_text_changed 'two'
        assert.spy(items[2].preview).was_called 1

      it 'displays the content returned by the preview method of the currently selected item', ->
        previewed_text = '<no-preview-set>'
        app.editor.preview = spy.new (e, buf) -> previewed_text = buf.text
        b = Buffer!
        b.text = 'buf-text'
        items = {
          {display_row: -> {'one'},
           preview: -> {text: 'hello'}},
          {display_row: -> {'two'},
           preview: -> {buffer: b}},
          {display_row: -> {'three'},
           preview: -> {chunk: b\chunk 1,2 }},
        }
        rebuild items
        assert.same 'hello', previewed_text

        -- should match the 'two' item and preview the buffer
        explorer_view\on_text_changed 'two'
        assert.same 'buf-text', previewed_text

        -- should match the 'three' item and preview the chunk
        explorer_view\on_text_changed 'three'
        assert.same 'buf-text', previewed_text

        -- clearing the text should go back to the first item
        explorer_view\on_text_changed ''
        assert.same 'hello', previewed_text

        -- also selects 'two' and previews the buffer
        keypress_binding_for 'cursor-down'
        assert.same 'buf-text', 'buf-text'

      it 'cancels preview when no item is selected', ->
        previewed_text = '<no-preview-set>'
        app.editor.preview = spy.new (e, buf) -> previewed_text = buf.text
        app.editor.cancel_preview = spy.new (e, buf) -> previewed_text = '<preview-cancelled>'
        b = Buffer!
        b.text = 'buf-text'
        items = {
          {display_row: -> {'one'},
           preview: -> {text: 'hello'}},
        }
        rebuild items
        assert.same 'hello', previewed_text
        explorer_view\on_text_changed 'two'
        assert.same '<preview-cancelled>', previewed_text


  context 'filtering', ->
    before_each ->
      explorer.display_items = spy.new -> {'one', 'two', 'three'}
      explorer_view = ExplorerView path: {explorer}
      explorer_view\init command_line, max_height: 100

    it 'displays filtered items when text is changed', ->
      explorer_view\on_text_changed 'on'
      assert.same {'one'}, list_widget_items!
      explorer_view\on_text_changed 'e'
      assert.same {'one', 'three'}, list_widget_items!

    it 'does not call display_items again when text is changed', ->
      explorer.display_items\clear!  -- reset the spy object
      explorer_view\on_text_changed 'o'
      explorer_view\on_text_changed 'on'
      assert.spy(explorer.display_items).was_called 0

  context 'changing levels', ->
    local finish_result

    before_each ->
      finish_result = '<finish-not-called>'
      explorer.display_items = spy.new -> {
        {'one'},
        {'two',
         display_items: -> {'a', 'b', 'c'},
         display_path: -> '[two]'
         display_title: -> 'Two'
        },
        {display_items: -> {'d', 'e', 'f'}
         display_path: -> '[three]'
         display_row: -> 'three-display'
        },
      }
      explorer_view = ExplorerView path: {explorer}, prompt: '[base]'
      command_line.finish = spy.new (_, result) -> finish_result = result
      explorer_view\init command_line, max_height: 100
      explorer_view\on_text_changed ''

    context 'when <enter> is pressed', ->
      it 'when selected item is not explorable, it finishes the command_line, returning item', ->
        keypress 'enter'
        assert.spy(command_line.finish).was_called 1
        assert.same {'one'}, finish_result

      it 'when selected item is explorable, it enters the new item, updating list', ->
        explorer_view\on_text_changed 'two'
        keypress 'enter'

        assert.spy(command_line.finish).was_not_called!
        assert.same {'a', 'b', 'c'}, list_widget_items!

      it 'when selected item is a display row produced by display_row, it enters the original explorer object', ->
        explorer_view\on_text_changed 'three'
        keypress 'enter'

        assert.spy(command_line.finish).was_not_called!
        assert.same {'d', 'e', 'f'}, list_widget_items!

      context 'when <backspace> is pressed', ->
        it 'goes back up one level', ->
          explorer_view\on_text_changed 'two'
          keypress 'enter'
          assert.same command_line.text, ''
          explorer_view\on_text_changed ''

          assert.same {'a', 'b', 'c'}, list_widget_items!
          keypress 'backspace'
          assert.same {'one'}, list_widget_items![1]
          assert.same '<finish-not-called>', finish_result

        it 'finishes command line with nil, when already at top level', ->
          assert.same '<finish-not-called>', finish_result
          keypress 'backspace'
          assert.is_nil finish_result

      it 'sets the prompt provided by display_path', ->
        explorer_view\on_text_changed 'two'
        keypress 'enter'
        assert.same '[base][two]', tostring command_line.prompt
        keypress 'backspace'
        assert.same '[base]', tostring command_line.prompt

      it 'sets the title provided by display_title', ->
        explorer_view\on_text_changed 'two'
        keypress 'enter'
        assert.same 'Two', tostring command_line.title
        keypress 'backspace'
        assert.is_nil command_line.title

  context 'quick parsing', ->
    local parse

    before_each ->
      explorer.display_items = -> {'one', 'two', 'three'}
      parse = ->
      explorer.parse = spy.new (...) -> parse ...
      explorer_view = ExplorerView path: {explorer}
      explorer_view\init command_line

    it 'calls explorer.parse on every text change', ->
      explorer_view\on_text_changed 'on'
      assert.spy(explorer.parse).was_called_with explorer, 'on'
      explorer_view\on_text_changed 'one'
      assert.spy(explorer.parse).was_called 2
      assert.spy(explorer.parse).was_called_with explorer, 'one'

    context 'when parse returns a response', ->
      context 'and the response contains jump_to', ->
        it 'appends that explorer to its current levels', ->
          parse = spy.new (_, text) ->
            return unless text == 'two'
            {jump_to: {display_items: -> {'a', 'b', 'c'}}}

          explorer_view\on_text_changed 'tw'
          assert.same {'two'}, list_widget_items!
          explorer_view\on_text_changed 'two'
          assert.same {'a', 'b', 'c'}, list_widget_items!
          keypress 'backspace'
          assert.same {'one', 'two', 'three'}, list_widget_items!

        it 'sets any remaining_text returned by parse as text for the new level', ->
          parse = spy.new (_, text) ->
            return unless text == 'two'
            {jump_to: {display_items: -> {'aa', 'bb', 'ca'}}, text: 'a'}

          explorer_view\on_text_changed 'two'
          -- a real command line will call on_text_changed when text is set on it
          -- here we verify that text is correct and simulate the call
          assert.same command_line.text, 'a'
          explorer_view\on_text_changed 'a'
          -- only matches items with 'a'
          assert.same {'aa', 'ca'}, list_widget_items!

        it 'sets the prompt, title and text ', ->
          parse = spy.new (_, text) ->
            return unless text == 'two'
            {
              jump_to: {
                display_items: -> {'a', 'b', 'c'}
                display_path: -> 'newpath>'
                display_title: -> 'New Title'
              }
              text: 'new-text'
            }
          explorer_view\on_text_changed 'two'
          assert.same 'newpath>', tostring command_line.prompt
          assert.same 'New Title', tostring command_line.title
          assert.same 'new-text', tostring command_line.text

      context 'and the response contains jump_to_absolute', ->
        it 'jumps to the returned path of explorer objects, replacing current state', ->
          parse = spy.new (_, text) ->
            return unless text == 'two'
            return {jump_to_absolute: {{display_items: -> {'outer'}}, {display_items: -> {'inner'}}}}
          explorer_view\on_text_changed 'two'
          assert.same {'inner'}, list_widget_items!
          keypress 'backspace'
          assert.same {'outer'}, list_widget_items!

  context 'actions', ->
    local actions, unhandled_keypress

    before_each ->
      explorer.display_items = -> {'one', 'two', 'three'}
      actions = -> {}
      explorer.actions = spy.new (...) -> actions ...
      explorer_view = ExplorerView path: {explorer}
      explorer_view\init command_line
      explorer_view\on_text_changed ''

      unhandled_keypress = (keystroke) ->
        event = {}
        source = 'test'
        translations = {keystroke}
        action = explorer_view.keymap.on_unhandled event, source, translations, explorer_view
        action! if action

    it 'calls explorer.actions if an unhandled keypress is encountered', ->
      assert.spy(explorer.actions).was_not_called!
      unhandled_keypress 'ctrl_u'
      assert.spy(explorer.actions).was_called!

    context 'when actions returns an actions table', ->
      it 'invokes the action method with matching keystrokes', ->
        action_handler = spy.new ->
        actions = ->
          some_action:
            keystrokes: {'ctrl_u'}
            handler: action_handler
        assert.spy(action_handler).was_not_called!
        unhandled_keypress 'ctrl_u'
        assert.spy(action_handler).was_called_with explorer, 'one'

      it 'when action method returns a response with jump_to, enters new explorer', ->
        actions = ->
          some_action:
            keystrokes: {'ctrl_u'}
            handler: -> {jump_to: {display_items: -> {'a', 'b', 'c'}}}
        unhandled_keypress 'ctrl_u'
        assert.same {'a', 'b', 'c'}, list_widget_items!

      it 'when action method returns a response with jump_to_absolute, replaces explorer stack', ->
        actions = ->
          some_action:
            keystrokes: {'ctrl_u'}
            handler: -> {jump_to_absolute: {{display_items: -> {'outer'}}, {display_items: -> {'inner'}}}}
        unhandled_keypress 'ctrl_u'
        assert.same {'inner'}, list_widget_items!
        keypress 'backspace'
        assert.same {'outer'}, list_widget_items!

  context 'when item provides get_value method', ->
    local finish_result, previewed_text
    before_each ->
      finish_result = '<finish-not-called>'
      command_line.finish = spy.new (_, result) -> finish_result = result

      previewed_text = '<no-preview-set>'
      app.editor.preview = spy.new (e, buf) -> previewed_text = buf.text

      explorer.get_value = -> '100'
      explorer.set_value = spy.new ->
      explorer.display_items = nil
      explorer.preview = (_, text) -> {text: 'preview-text:' .. text}

    context 'when get_options is nil', ->
      before_each ->
        explorer.get_options = ->
        explorer_view = ExplorerView path: {explorer}
        explorer_view\init command_line
        explorer_view\on_text_changed ''

      it 'sets the command_line text to the value returned by get_value', ->
        assert.same '100', command_line.text

      it 'does not display the list widget', ->
        assert.is_falsy list_widget.showing

      it 'calls set_value when text is changed, passing new text', ->
        explorer_view\on_text_changed 'new-value'
        assert.spy(explorer.set_value).was_called_with explorer, 'new-value'

      it 'displays the preview for the item as text changes`', ->
        assert.same previewed_text, 'preview-text:'
        explorer_view\on_text_changed 'hello'
        assert.same previewed_text, 'preview-text:hello'

    context 'when get_options is a list of options', ->
      before_each ->
        explorer.get_options = -> {{'opt-a', value:'a'}, {'opt-b', value:'b'}}
        explorer.get_value = -> 'b'
        explorer.set_value = spy.new ->
        explorer.display_items = nil

        explorer_view = ExplorerView path: {explorer}
        explorer_view\init command_line
        explorer_view\on_text_changed ''

      it 'displays the list of options', ->
        assert.is_true list_widget.showing
        assert.same {'opt-a', 'opt-b'}, [item[1] for item in *list_widget_items!]

      it 'shows the current value as seleted', ->
        assert.same {'opt-b', value:'b'}, list_widget.list.selection

      it 'lets you filter options by typing', ->
        explorer_view\on_text_changed 'a'
        assert.same {'opt-a'}, [item[1] for item in *list_widget_items!]

      it 'selecting an option finishes with the selection set with the new value', ->
        keypress_binding_for 'cursor-up'  -- default is 'b', this selects 'a'
        keypress 'enter'
        assert.spy(command_line.finish).was_called 1
        assert.equal explorer, finish_result
        assert.spy(explorer.set_value).was_called 1
        assert.spy(explorer.set_value).was_called_with explorer, 'a'

      it 'displays the preview for the item as selection changes`', ->
        assert.same 'preview-text:b', previewed_text
        keypress_binding_for 'cursor-up'
        assert.same 'preview-text:a', previewed_text
