-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, Buffer from howl
import Editor, Window from howl.ui

append = table.insert

require 'howl.interactions.selection_list'
require 'howl.interactions.location_selection'
require 'howl.interactions.line_selection'

describe 'select_line', ->
  local command_line, buffer, editor

  before_each ->
    app.window = Window!
    app.window\realize!
    command_line = app.window.command_line

    buffer = Buffer!
    buffer.text = 'one\ntwo\nthree'
    editor = Editor buffer

  it "registers interactions", ->
    assert.not_nil interact.select_line

  describe 'interact.select_line', ->
    it 'shows opt.lines in the completion list by default', ->
      local lines
      within_activity (-> interact.select_line(:editor, lines: buffer.lines)), ->
        lines = get_ui_list_widget_column 2
      assert.same {'one', 'two', 'three'}, lines

    it 'filters lines to match text entered', ->
      lines = {}
      within_activity (-> interact.select_line(:editor, lines: buffer.lines)), ->
        append lines, get_ui_list_widget_column 2
        command_line\write 'o'
        append lines, get_ui_list_widget_column 2
        command_line\write 'n'
        append lines, get_ui_list_widget_column 2
        command_line\clear!
        command_line\write ''
        append lines, get_ui_list_widget_column 2

      assert.same {'one', 'two', 'three'}, lines[1]
      assert.same {'one', 'two'}, lines[2]
      assert.same {'one'}, lines[3]
      assert.same {'one', 'two', 'three'}, lines[4]

    context 'when `find` function is provided', ->
      it 'uses the find function to find matching lines', ->
        find = (query, text) ->
          return {{1,3}} if text == 'two'
        local lines
        within_activity (-> interact.select_line(:editor, lines: buffer.lines, :find)), ->
          command_line\write 'abc'
          lines = get_ui_list_widget_column 2
        assert.same {'two'}, lines
