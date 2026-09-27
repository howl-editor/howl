-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Buffer from howl
import Editor, CompletionPopup from howl.ui

describe 'CompletionPopup', ->
  context 'resource management', ->
    editor = Editor Buffer!

    it 'popups are collected as they should', ->
      o = CompletionPopup editor
      list = setmetatable {o}, __mode: 'v'
      o\release!
      o = nil
      collectgarbage!
      assert.is_true list[1] == nil, 'Object still lives'

  context 'with an asynchronous completer', ->
    local editor, buffer, popup, completions, notify

    before_each ->
      completions = {}
      buffer = Buffer word_pattern: r'\\w+'
      buffer.completers = {
        (_, _, on_update) ->
          notify = on_update
          complete: -> completions
      }
      editor = Editor buffer
      editor.show_completion_popup = spy.new ->
      popup = CompletionPopup editor
      buffer.text = 'foo ba'
      editor.cursor.pos = 7
      popup\complete!

    after_each -> popup\release!

    it 'asks the editor to show the popup when late completions arrive', ->
      assert.is_true popup.empty
      completions = { 'bar' }
      notify!
      assert.same { 'bar' }, popup.items
      assert.spy(editor.show_completion_popup).was_called(1)

    it 'does not show the popup if the late completions are empty', ->
      notify!
      assert.spy(editor.show_completion_popup).was_not_called!

    it 'ignores updates for a previous completion session', ->
      old_notify = notify
      popup\close!
      popup\complete!
      completions = { 'bar' }
      old_notify!
      assert.spy(editor.show_completion_popup).was_not_called!

    it 'ignores updates once the cursor has left the completed word', ->
      editor.cursor.pos = 4
      completions = { 'bar' }
      notify!
      assert.spy(editor.show_completion_popup).was_not_called!
