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




  -- describe 'parse_path', ->
  --   it 'returns the home dir for empty input', ->
  --     assert.same {file_selection.home_dir!, ''}, {file_selection.parse_path ''}

  --   it 'returns the root directory for "/"', ->
  --     assert.same {file_selection.root_dir!, ''}, {file_selection.parse_path '/'}

  --   it 'returns the matched path and unmatched parts of a path', ->
  --     assert.same {tmpdir, 'unmatched'}, {file_selection.parse_path tostring(tmpdir / 'unmatched')}

  --   it 'unmatched part can contain slashes', ->
  --     assert.same {tmpdir, 'unmatched/no/such/file'}, {file_selection.parse_path tostring(tmpdir / 'unmatched/no/such/file')}

  -- describe 'interact.select_file', ->
  --   it 'opens the home directory by default', ->
  --     local prompt
  --     within_activity interact.select_file, ->
  --       print 'running activity!'
  --       prompt = command_line.prompt
  --     assert.same '~/', prompt

  --   it 'typing a path opens the closest parent', ->
  --     prompts = {}
  --     within_activity interact.select_file, ->
  --       command_line\write tostring(tmpdir)
  --       table.insert prompts, command_line.prompt
  --     assert.same {tostring(tmpdir.parent) .. '/'}, prompts

  --   it 'typing "/" after a directory name opens the directory', ->
  --     local prompt
  --     within_activity interact.select_file, ->
  --       command_line\write tostring(tmpdir) .. '/'
  --       prompt = command_line.prompt
  --     assert.same tostring(tmpdir) .. '/', prompt

  --   it 'typing "../" switches to the parent of the current directory', ->
  --     prompts = {}
  --     within_activity interact.select_file, ->
  --       command_line\write tostring(tmpdir) .. '/'
  --       table.insert prompts, command_line.prompt
  --       command_line\write tostring(tmpdir) .. '../'
  --       table.insert prompts, command_line.prompt
  --     assert.same {tostring(tmpdir) .. '/', tostring(tmpdir.parent) .. '/'}, prompts

  --   it 'typing "/" without any preceeding text changes to home directory', ->
  --     local prompt
  --     within_activity interact.select_file, ->
  --       command_line\write '/'
  --       prompt = command_line.prompt
  --     assert.same '/', prompt

  --   it 'shows files matching entered text in the current directory', ->
  --     files = { 'ab1', 'ab2', 'bc1' }
  --     for f in *files
  --       f = tmpdir / f
  --       f.contents = 'a'

  --     local items, items2
  --     within_activity interact.select_file, ->
  --       command_line\write tostring(tmpdir) .. '/'
  --       items = get_list_items(1)

  --       command_line\write 'ab'
  --       items2 = get_list_items(1)

  --     assert.same files, items
  --     assert.same {'ab1', 'ab2'}, items2

  -- describe 'interact.select_directory', ->
  --   it 'shows only sub directories including "./", but no files', ->
  --     files = { 'ab1', 'ab2', 'bc1' }
  --     directories = { 'dir1', 'dir2' }
  --     for f in *files
  --       f = tmpdir / f
  --       f.contents = 'a'

  --     for d in *directories
  --       f = tmpdir / d
  --       f\mkdir!

  --     local items
  --     within_activity interact.select_directory, ->
  --       command_line\write tostring(tmpdir) .. '/'
  --       items = get_list_items(1)

  --     assert.same { './', 'dir1/', 'dir2/' }, items
