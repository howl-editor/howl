-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, bindings, config, interact, Project from howl
import File from howl.io
import Window from howl.ui

require 'howl.ui.icons.font_awesome'
require 'howl.interactions.explorer'
require 'howl.interactions.select'
require 'howl.interactions.location_selection'
require 'howl.interactions.buffer_selection'

list_items = (command_line, col=1) ->
  [tostring(item[col]) for item in *command_line\get_widget('explore_list').list.items]

describe 'buffer_selection', ->
  local editor, preview_title
  buffers = {}

  before_each ->
    app.window = Window!
    app.window\realize!
    preview_title = '<no-preview-buffer>'
    editor = {
      preview: (buffer) => preview_title = buffer.title
    }

    config.autoclose_single_buffer = false

    for b in *app.buffers
      app\close_buffer b

    for title in *{'a1-buffer', 'b-buffer', 'c-buffer', 'a2-buffer'}
      b = app\new_buffer!
      b.title = title
      table.insert buffers, b

  it "registers interactions", ->
    assert.not_nil interact.select_buffer

  describe 'interact.select_buffer', ->
    it 'displays a list of active buffers', ->
      local buflist
      within_command_line (-> interact.select_buffer :editor), (command_line) ->
        buflist = list_items command_line, 2
      assert.same {'a1-buffer', 'a2-buffer', 'b-buffer', 'c-buffer'}, buflist

    it 'filters the buffer list based on entered text', ->
      local buflist
      within_command_line  (-> interact.select_buffer :editor), (command_line) ->
        command_line\write 'a-b'
        buflist = list_items command_line, 2
      assert.same {'a1-buffer', 'a2-buffer'}, buflist

    it 'previews currently selected buffer in the editor', ->
      previews = {}
      down_event = {
        key_code: 65364
        key_name: 'down'
        alt: false
        control: false
        meta: false
        shift: false
        super: false
      }

      within_command_line  (-> interact.select_buffer :editor), (command_line) ->
        table.insert previews, preview_title
        command_line\handle_keypress down_event
        table.insert previews, preview_title
      assert.same {'a1-buffer', 'a2-buffer'}, previews

    context 'sending binding_for("buffer-close")', ->
      keymap = ctrl_w: 'buffer-close'
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
        within_command_line  (-> interact.select_buffer :editor), (command_line) ->
          command_line\handle_keypress close_event
          command_line\handle_keypress close_event
          buflist = list_items command_line, 2
        assert.same {'b-buffer', 'c-buffer'}, buflist

      it 'preserves filter', ->
        local buflist
        within_command_line  (-> interact.select_buffer :editor), (command_line) ->
          command_line\write 'a-b'
          command_line\handle_keypress close_event
          buflist = list_items command_line, 2
        assert.same {'a2-buffer'}, buflist

    context 'duplicate filenames', ->
      before_each ->
        for b in *app.buffers
          app\close_buffer b

        paths = {'/project1/some/file1', '/project2/some/file1', '/project2/path1/file2', '/project2/path2/file2'}
        for path in *paths
          b = app\new_buffer!
          b.file = File path

        Project.add_root File '/project1'
        Project.add_root File '/project2'

      it 'uniquifies title by using project name and parent directory prefix', ->
        local buflist
        within_command_line  (-> interact.select_buffer :editor), (command_line) ->
          buflist = list_items command_line, 2
        assert.same {'file1 [project1]', 'file1 [project2]', 'path1/file2', 'path2/file2'}, buflist
