-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, Buffer from howl
import Editor, Window from howl.ui

append = table.insert

grep_search = require 'howl.interactions.grep_search'
grep_search = require 'howl.interactions.selection_list'

describe 'grep_search', ->
  local command_line, buffer, editor

  before_each ->
    app.window = Window!
    app.window\realize!
    command_line = app.window.command_line

    buffer = Buffer!
    buffer.text = 'one\ntwo\nthree'
    editor = Editor buffer

  it "registers interactions", ->
    assert.not_nil interact.select_match

  describe 'interact.select_match', ->
    it 'shows all lines in the completion list by default', ->
      local lines
      within_activity (-> interact.select_match(:editor)), ->
        lines = get_list_items 2
      assert.same {'one', 'two', 'three'}, lines

    it 'shows lines that match text entered', ->
      lines = {}
      within_activity (-> interact.select_match(:editor)), ->
        append lines, get_list_items 2
        command_line\write 'o'
        append lines, get_list_items 2
        command_line\write 'n'
        append lines, get_list_items 2
        command_line\clear!
        command_line\write ''
        append lines, get_list_items 2

      assert.same {'one', 'two', 'three'}, lines[1]
      assert.same {'one', 'two'}, lines[2]
      assert.same {'one'}, lines[3]
      assert.same {'one', 'two', 'three'}, lines[4]

    context 'when opts.lines is provided',
      it 'shows opts.lines in the completion list', ->
        local lines
        within_activity (-> interact.select_match(:editor, lines:{buffer.lines[1]})), ->
          lines = get_list_items 2
        assert.same {'one'}, lines
