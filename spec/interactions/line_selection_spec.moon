-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, Buffer from howl
import Editor, Window from howl.ui

append = table.insert

require 'howl.interactions.explorer'
require 'howl.interactions.select'
require 'howl.interactions.location_selection'
require 'howl.interactions.line_selection'

list_items = (command_line, col=1) ->
  [tostring(item[col]) for item in *command_line\get_widget('explore_list').list.items]

describe 'select_line', ->
  local buffer, editor

  before_each ->
    app.window = Window!
    app.window\realize!
    buffer = Buffer!
    buffer.text = 'one\ntwo\nthree'
    editor = Editor buffer

  it "registers interactions", ->
    assert.not_nil interact.select_line

  describe 'interact.select_line', ->
    it 'shows opt.lines in the completion list by default', ->
      local lines
      within_command_line (-> interact.select_line(:editor, lines: buffer.lines)), (command_line) ->
        lines = list_items command_line, 2
      assert.same {'one', 'two', 'three'}, lines

    it 'filters lines to match text entered', ->
      lines = {}
      within_command_line (-> interact.select_line(:editor, lines: buffer.lines)), (command_line) ->
        append lines, list_items command_line, 2
        command_line\write 'o'
        append lines, list_items command_line, 2
        command_line\write 'n'
        append lines, list_items command_line, 2
        command_line\clear!
        command_line\write ''
        append lines, list_items command_line, 2

      assert.same {'one', 'two', 'three'}, lines[1]
      assert.same {'one', 'two'}, lines[2]
      assert.same {'one'}, lines[3]
      assert.same {'one', 'two', 'three'}, lines[4]
