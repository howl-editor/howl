-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, config, interact from howl
import File from howl.io
import Window from howl.ui
require 'howl.ui.icons.font_awesome'
require 'howl.interactions.explorer'
require 'howl.interactions.file_selection'

list_items = (command_line, col=1) ->
  [tostring(item[col]) for item in *command_line\get_widget('explore_list').list.items]

describe 'file_selection', ->
  local tmpdir

  before_each ->
    for buf in *app.buffers
      app\close_buffer buf

    app.window = Window!
    app.window\realize!
    app.editor = app\new_editor!
    tmpdir = File.tmpdir!
    howl.config.file_icons = true

  after_each ->
    tmpdir\rm_r!
    for buf in *app.buffers
      app\close_buffer buf
    app.editor = nil
    app.window\destroy!
    app.window = nil

  it "registers interactions", ->
    assert.not_nil interact.select_file
    assert.not_nil interact.select_file_in_project
    assert.not_nil interact.select_directory

  describe 'interact.select_file', ->
    it 'opens the home directory by default', ->
      local prompt

      within_command_line interact.select_file, (command_line) ->
        prompt = tostring command_line.prompt
      assert.same '~/', prompt

    it 'typing a path opens the closest parent', ->
      prompts = {}
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring tmpdir
        table.insert prompts, tostring command_line.prompt
      assert.same {tostring(tmpdir.parent) .. '/'}, prompts

    it 'typing "/" after a directory name opens the directory', ->
      local prompt
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring(tmpdir) .. '/'
        prompt = tostring command_line.prompt
      assert.same tostring(tmpdir) .. '/', prompt

    it 'typing "../" switches to the parent of the current directory', ->
      prompts = {}
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring(tmpdir) .. '/'
        table.insert prompts, tostring command_line.prompt
        command_line\write '../'
        table.insert prompts, tostring command_line.prompt
      assert.same {tostring(tmpdir) .. '/', tostring(tmpdir.parent) .. '/'}, prompts

    it 'typing "/" without any preceeding text changes to home directory', ->
      local prompt
      within_command_line interact.select_file, (command_line) ->
        command_line\write '/'
        prompt = tostring command_line.prompt
      assert.same '/', prompt

    it 'shows files matching entered text in the current directory', ->
      files = { 'ab1', 'ab2', 'bc1' }
      for f in *files
        f = tmpdir / f
        f.contents = 'a'

      local items, items2
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring(tmpdir) .. '/'
        items = list_items command_line, 2
        command_line\write 'ab'
        items2 = list_items command_line, 2

      assert.same files, items
      assert.same {'ab1', 'ab2'}, items2

    context 'when config.hidden_file_extensions is set', ->
      local files

      before_each ->
        config.reset!
        config.hidden_file_extensions = {'a'}
        files = { 'x.a', 'x.b', 'x.c' }
        for f in *files
          f = tmpdir / f
          f.contents = 'x'

      it 'does not show hidden files in list', ->
        local items
        within_command_line interact.select_file, (command_line) ->
          command_line\write tostring(tmpdir) .. '/'
          items = list_items command_line, 2
        assert.same { 'x.b', 'x.c' }, items

      it 'shows a hidden file after its exact name is entered', ->
        local items, statuses
        within_command_line interact.select_file, (command_line) ->
          command_line\write tostring(tmpdir) .. '/'
          command_line\write 'x.a'
          items = list_items command_line, 2
          statuses = list_items command_line, 3

        assert.same { 'x.a' }, items
        assert.same { '[hidden]' }, statuses

    context 'in subtree mode', ->
      it 'shows files and directories in the subtree', ->
        files = { 'ab1', 'ab2/', 'ab2/xy', 'ef/', 'ef/gh/', 'ef/gh/ab4'}
        for name in *files
          f = tmpdir / name
          if name\ends_with '/'
            f\mkdir!
          else
            f.contents = 'a'

        local items, items2
        within_command_line (-> interact.select_file(path: tostring(tmpdir) .. '/', show_subtree: true)), (command_line) ->
          items = list_items command_line, 2
          command_line\write 'ab'
          items2 = list_items command_line, 2
          table.sort items
          table.sort items2

        assert.same files, items
        assert.same {'ab1', 'ab2/', 'ab2/xy','ef/gh/ab4'}, items2

  describe 'interact.select_directory', ->
    it 'shows only sub directories including "./", but no files', ->
      files = { 'ab1', 'ab2', 'bc1' }
      directories = { 'dir1', 'dir2' }
      for f in *files
        f = tmpdir / f
        f.contents = 'a'

      for d in *directories
        f = tmpdir / d
        f\mkdir!

      local items
      within_command_line interact.select_directory, (command_line) ->
        command_line\write tostring(tmpdir) .. '/'
        items = list_items command_line, 2

      assert.same { './', 'dir1/', 'dir2/' }, items


    it 'typing a path opens the closest parent', ->
      prompts = {}
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring(tmpdir)
        table.insert prompts, tostring command_line.prompt
      assert.same {tostring(tmpdir.parent) .. '/'}, prompts

    it 'typing "/" after a directory name opens the directory', ->
      local prompt
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring(tmpdir) .. '/'
        prompt = tostring command_line.prompt
      assert.same tostring(tmpdir) .. '/', prompt

    it 'typing a trailing "/~/" jumps to the home directory', ->
      prompts = {}
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring(tmpdir) .. '/'
        table.insert prompts, tostring command_line.prompt
        command_line\write '~/'
        table.insert prompts, tostring command_line.prompt
      assert.same {tostring(tmpdir) .. '/', '~/'}, prompts

    context 'for directory names ending with ~', ->
      before_each -> File.mkdir tmpdir / 'subdir~'

      it 'typing subdir~/ switches to the directory', ->
        prompts = {}
        within_command_line interact.select_file, (command_line) ->
          command_line\write tostring(tmpdir) .. '/subdir~/'
          table.insert prompts, tostring command_line.prompt
        assert.same {tostring(tmpdir) .. '/subdir~/'}, prompts

    it 'typing "../" switches to the parent of the current directory', ->
      prompts = {}
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring(tmpdir) .. '/'
        table.insert prompts, tostring command_line.prompt
        command_line\write tostring(tmpdir) .. '../'
        table.insert prompts, tostring command_line.prompt
      assert.same {tostring(tmpdir) .. '/', tostring(tmpdir.parent) .. '/'}, prompts

    it 'typing "/" without any preceeding text changes to home directory', ->
      local prompt
      within_command_line interact.select_file, (command_line) ->
        command_line\write '/'
        prompt = tostring command_line.prompt
      assert.same '/', prompt

    it 'shows files matching entered text in the current directory', ->
      files = { 'ab1', 'ab2', 'bc1' }
      for f in *files
        f = tmpdir / f
        f.contents = 'a'

      local items, items2
      within_command_line interact.select_file, (command_line) ->
        command_line\write tostring(tmpdir) .. '/'
        items = list_items command_line, 2

        command_line\write 'ab'
        items2 = list_items command_line, 2

      assert.same files, items
      assert.same {'ab1', 'ab2'}, items2
