-- Copyright 2018 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import SearchView, NotificationWidget from howl.ui
match = require 'luassert.match'


describe 'SearchView', ->
  local command_line, search_view, list_widget, editor, buffer, finish_result, search, preview_buffer, error_message, info_message, find_iter_count

  keypress = (keystroke) ->
    search_view.keymap[keystroke] search_view
    howl.app\pump_mainloop!  -- allow all timer.asap functions to run

  keypress_binding_for = (cmd) ->
    search_view.keymap.binding_for[cmd] search_view
    howl.app\pump_mainloop!  -- allow all timer.asap functions to run

  set_text = (sv, text) ->
    command_line.text = text
    sv\on_text_changed text
    -- wait for searcher to be done, since it runs in a separate coroutine
    if sv.searcher.running
      howl.dispatch.wait sv.searcher.running
    howl.app\pump_mainloop!  -- allow all timer.asap functions to run


  list_widget_items = -> list_widget.list._items
  list_widget_height = -> list_widget.height
  found_count = ->
    return unless info_message
    _, _, count = info_message\find '(%d+) match'
    tonumber count

  before_each ->
    preview_buffer = nil
    editor = {
      preview: spy.new (b) => preview_buffer = b
      cancel_preview: spy.new =>
      line_at_top: 1
      line_at_bottom: 1
    }
    command_line =
      add_widget: spy.new (name, w) => list_widget = w if name == 'matches'
      notification: NotificationWidget!
      finish: spy.new (r) => finish_result = r

    info_message = '<not-set>'
    error_message = '<not-set>'
    command_line.notification.error = spy.new (self, msg) -> error_message = msg
    command_line.notification.info = spy.new (self, msg) -> info_message = msg
    command_line.notification.clear = spy.new (self, msg) ->
      info_message = ''
      error_message = ''

    buffer = howl.Buffer!
    editor.buffer = buffer
    search = spy.new (query) ->
      -- an iterator that returns buffer chunks from ufind
      return if query.is_empty

      start = 1
      find_iter_count = 0
      text = buffer.text
      ->
        start_pos, end_pos = text\ufind query, start, true
        return unless start_pos
        start = end_pos + 1
        find_iter_count += 1
        buffer\chunk start_pos, end_pos

  context 'on initialization', ->
    it 'calls add_widget on the passed command line, adding a list widget', ->
      search_view = SearchView
        editor: editor
        buffer: buffer
        :search
      search_view\init command_line, max_height: 100
      assert.spy(command_line.add_widget).was_called 1
      assert.same "ListWidget", typeof(list_widget)

    it 'displays the specified prompt and title', ->
      search_view = SearchView
        editor: editor
        buffer: buffer
        :search
        prompt: 'hello>'
        title: '#hello'
      search_view\init command_line, max_height: 100
      assert.same 'hello>', command_line.prompt
      assert.same '#hello', command_line.title

    it 'displays no info message', ->
      buffer.text = 'content'
      search_view = SearchView
        editor: editor
        buffer: buffer
        :search
      search_view\init command_line, max_height: 100
      set_text search_view, ''
      assert.is_nil found_count!

    it 'displays all lines of buffer', ->
      buffer.text = 'hello1\nhello2\nhello3'
      search_view = SearchView
        editor: editor
        buffer: buffer
        :search
      search_view\init command_line, max_height: 100
      set_text search_view, ''
      items = list_widget_items!
      assert.same {'hello1', 'hello2', 'hello3'}, [item[2].text for item in *items]
      assert.same {}, [item.item_highlights for item in *items]

    it 'does not call search for empty query', ->
      search = spy.new ->
      search_view = SearchView
        editor: editor
        buffer: buffer
        :search
      search_view\init command_line, max_height: 100
      set_text search_view, ''
      assert.spy(search).was_not_called!

  context 'searching', ->
    it 'calls search(query) iterator when text is updated', ->
      buffer.text = 'buffer-content'
      search_view = SearchView
        :editor
        :buffer
        :search
      search_view\init command_line, max_height: 100
      set_text search_view, 'query-target'
      assert.spy(search).was_called_with 'query-target'

    context 'when query text is set', ->
      before_each ->
        buffer.text = 'cöntent-line1\ncöntent-line12\ncontent-line3'
        search_view = SearchView
          :editor
          :buffer
          :search
        search_view\init command_line, max_height: 100

      it 'iterates over search(query)', ->
        set_text search_view, 'line1'
        assert.spy(search).was_called 1
        assert.spy(search).was_called_with 'line1'
        assert.same 2, find_iter_count

      it 'displays the matching lines, at most one match per line', ->
        set_text search_view, 'line1'
        items = list_widget_items!
        assert.same {1, 2}, [item[1] for item in *items]
        assert.same {'cöntent-line1', 'cöntent-line12'}, [item[2].text for item in *items]

        set_text search_view, 'line3'
        items = list_widget_items!
        assert.same {3}, [item[1] for item in *items]
        assert.same {'content-line3'}, [item[2].text for item in *items]

      it 'displays an info message with match count', ->
        set_text search_view, 'line1'
        assert.same 2, found_count!
        set_text search_view, 'line12'
        assert.same 1, found_count!
        set_text search_view, 'line-'
        assert.same 0, found_count!

      it 'resets info message when query text is cleared', ->
        set_text search_view, 'line1'
        assert.same 2, found_count!
        set_text search_view, ''
        assert.is_nil found_count!

      it 'does not shrink diplayed list widget size', ->
        set_text search_view, 'li'
        height = list_widget_height!
        set_text search_view, 'line1'
        assert.same height, list_widget_height!

      context 'selected line', ->
        it 'is centered', ->
          set_text search_view, 'line1'
          assert.same 1, editor.line_at_center

        it 'is changed by keypresses', ->
          set_text search_view, 'line1'
          keypress_binding_for 'cursor-down'
          assert.same 2, editor.line_at_center
          keypress_binding_for 'cursor-up'
          assert.same 1, editor.line_at_center

      it 'returns selected match on pressing enter', ->
        set_text search_view, 'line1'
        assert.spy(command_line.finish).was_not_called!
        keypress_binding_for 'cursor-down'
        keypress 'enter'
        assert.spy(command_line.finish).was_called 1
        assert.same 23, finish_result.chunk.start_pos
        assert.same 27, finish_result.chunk.end_pos

      it 'displays error message on pressing enter when no selection', ->
        set_text search_view, 'xxxxxxxxxxxxx'
        keypress 'enter'
        assert.spy(command_line.finish).was_not_called!
        assert.spy(command_line.notification.error).was_called 1
        assert.same error_message, 'No selection'

    context 'when search raises an error', ->
      before_each ->
        search_view = SearchView
          :editor
          :buffer
          search: -> error 'search-error', 0
        search_view\init command_line, max_height: 100

      it 'displays the error message', ->
        set_text search_view, 'query'
        assert.same 'search-error', error_message

    context 'when limit is set', ->
      before_each ->
        buffer.text = 'a a a a a a a a'
        search_view = SearchView
          :editor
          :buffer
          :search
          limit: 3
        search_view\init command_line, max_height: 100

      it 'does not iterate once limit matches are found', ->
        set_text search_view, 'a'
        assert.same 3, find_iter_count

  context 'replacing', ->
    local replace

    before_each ->
      replace = spy.new (_, _, _, replacement)-> replacement
      search = spy.new (query) ->
        return if query.is_empty

        start = 1
        find_iter_count = 0
        text = buffer.text
        ->
          start_pos, end_pos = text\ufind query, start, true
          return unless start_pos
          start = end_pos + 1
          find_iter_count += 1
          buffer\chunk(start_pos, end_pos), 'match-info'


    it 'parses query and calls search(query) with the search part', ->
      buffer.text = 'buffer-content'
      search_view = SearchView
        :editor
        :buffer
        :search
        :replace
      search_view\init command_line, max_height: 100
      set_text search_view, '/search'
      assert.spy(search).was_called_with 'search'

    it 'displays all matches', ->
      buffer.text = 'cöntent-line1\ncöntent-line2\n'
      search_view = SearchView
        :editor
        :buffer
        :search
        :replace
      search_view\init command_line, max_height: 100
      set_text search_view, '/t'
      assert.same {'cöntent-line1', 'cöntent-line1', 'cöntent-line2', 'cöntent-line2'}, [item[2].text for item in *list_widget_items!]

    context 'when the query includes a replacement', ->
      before_each ->
        buffer.text = 'content-line1\ncontent-line2\n'
        search_view = SearchView
          :editor
          :buffer
          :search
          :replace
        search_view\init command_line, max_height: 100

      it 'calls replace for each match', ->
        set_text search_view, '/content/<new>'
        assert.spy(replace).was_called 2
        assert.spy(replace).was_called_with match._, 'match-info', match._, '<new>'

      it 'displays a preview with replacements applied', ->
        editor.line_at_top = 1
        editor.line_at_bottom = 2

        set_text search_view, '/line/<new>'
        assert.spy(editor.preview).was_called 1
        assert.same 'content-<new>1\ncontent-<new>2\n', preview_buffer.text
        assert.same {'search'}, howl.ui.highlight.at_pos preview_buffer, 9

      it 'returns text with replacements applied as previewed', ->
        set_text search_view, '/line/<new>'
        text = preview_buffer.text
        keypress 'enter'
        assert.same text, finish_result.replacement_text
        assert.same 2, finish_result.replacement_count

      context 'if no replacement text', ->
        it 'previews deletions using strikeout style', ->
          editor.line_at_top = 1
          editor.line_at_bottom = 2

          set_text search_view, '/line/'
          text = preview_buffer.text
          assert.same buffer.text, text
          assert.same {'replace_strikeout', 'search'}, howl.ui.highlight.at_pos preview_buffer, 9
          assert.same {'replace_strikeout', 'search'}, howl.ui.highlight.at_pos preview_buffer, 10

        it 'returns text with deletions applied', ->
          set_text search_view, '/line/'
          keypress 'enter'
          assert.same 'content-1\ncontent-2\n', finish_result.replacement_text

      context 'if no trailing delimiter', ->
        it 'previews existing buffer', ->
          set_text search_view, '/line'
          assert.equal preview_buffer, buffer

        it 'returns nil', ->
          set_text search_view, '/line'
          keypress 'enter'
          assert.is_nil finish_result
