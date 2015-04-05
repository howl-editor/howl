-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, bindings, interact from howl
import Window from howl.ui

require 'howl.interactions.buffer_selection'
require 'howl.interactions.selection_list'

describe 'buffer_selection', ->
  local command_line
  buffers = {}

  before_each ->
    app.window = Window!
    app.window\realize!
    command_line = app.window.command_line

    for title in *{'a1-buffer', 'b-buffer', 'c-buffer', 'a2-buffer'}
      b = app\new_buffer!
      b.title = title
      table.insert buffers, b

  after_each ->
      for b in *app.buffers
        app\close_buffer b

  normalize_titles = (titles) -> [t\gsub('<.*>', '') for t in *titles]

  it "registers interactions", ->
    assert.not_nil interact.select_buffer

  describe 'interact.select_buffer', ->
    it 'displays a list of active buffers', ->
      local buflist
      within_activity interact.select_buffer, ->
        buflist = get_list_items!
      assert.same {'a1-buffer', 'a2-buffer', 'b-buffer', 'c-buffer'}, normalize_titles buflist

    it 'filters the buffer list based on entered text', ->
      local buflist
      within_activity interact.select_buffer, ->
        command_line\write 'a-b'
        buflist = get_list_items!
      assert.same {'a1-buffer', 'a2-buffer'}, normalize_titles buflist

    context 'sending binding_for("close")', ->
      keymap = ctrl_w: 'close'
      before_each -> bindings.push keymap
      after_each -> bindings.remove keymap

      close_event = {
        alt: false,
        character: "w",
        control: true,
        key_code: 119,
        key_name: "w",
        meta: false,
        shift: false,
        super: false
      }

      it 'closes selected buffer', ->
        local buflist
        within_activity interact.select_buffer, ->
          command_line\handle_keypress close_event
          command_line\handle_keypress close_event
          buflist = get_list_items!
        assert.same {'b-buffer', 'c-buffer'}, normalize_titles buflist

      it 'preserves filter', ->
        local buflist
        within_activity interact.select_buffer, ->
          command_line\write 'a-b'
          command_line\handle_keypress close_event
          buflist = get_list_items!
        assert.same {'a2-buffer'}, normalize_titles buflist
