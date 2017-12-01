-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, config, interact from howl
import File from howl.io
import Window from howl.ui
require 'howl.ui.icons.font_awesome'
require 'howl.interactions.file_selection'
pathsep = File.separator

describe 'file_selection', ->
  local tmpdir, command_line

  before_each ->
    for buf in *app.buffers
      app\close_buffer buf

    app.window = Window!
    app.window\realize!
    app.editor = app\new_editor!
    command_line = app.window.command_line
    tmpdir = File.tmpdir!

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
      within_activity interact.select_file, ->
        prompt = command_line.prompt
      assert.same "~#{pathsep}", prompt

    context 'when a buffer associated with a file is open', ->
      it 'opens the directory of the current buffer, if any', ->
        _, app.editor = app\open_file tmpdir / 'f'
        local prompt
        within_activity interact.select_file, ->
          prompt = command_line.prompt
        assert.same tostring(tmpdir)..pathsep, File.expand_path prompt

    it 'typing a path opens the closest parent', ->
      prompts = {}
      within_activity interact.select_file, ->
        command_line\write tostring(tmpdir)
        table.insert prompts, File.expand_path command_line.prompt
      assert.same {tostring(tmpdir.parent) .. pathsep}, prompts

    it 'typing "/" after a directory name opens the directory', ->
      local prompt
      within_activity interact.select_file, ->
        command_line\write tostring(tmpdir) .. '/'
        prompt = command_line.prompt
      assert.same tostring(tmpdir) .. pathsep, File.expand_path prompt

    it 'typing "../" switches to the parent of the current directory', ->
      prompts = {}
      within_activity interact.select_file, ->
        command_line\write tostring(tmpdir) .. '/'
        table.insert prompts, File.expand_path command_line.prompt
        command_line\write tostring(tmpdir) .. '/../'
        table.insert prompts, File.expand_path command_line.prompt
      assert.same {tostring(tmpdir) .. pathsep, tostring(tmpdir.parent) .. pathsep}, prompts

    it 'typing "/" without any preceeding text changes to home directory', ->
      local prompt
      within_activity interact.select_file, ->
        command_line\write '/'
        prompt = command_line.prompt
      assert.same pathsep, prompt

    it 'shows files matching entered text in the current directory', ->
      files = { 'ab1', 'ab2', 'bc1' }
      for f in *files
        f = tmpdir / f
        f.contents = 'a'

      local items, items2
      within_activity interact.select_file, ->
        command_line\write tostring(tmpdir) .. '/'
        items = get_ui_list_widget_column(2)

        command_line\write 'ab'
        items2 = get_ui_list_widget_column(2)

      assert.same files, items
      assert.same {'ab1', 'ab2'}, items2

    context 'spillover', ->
      context 'when spillover is not an absolute path', ->
        it 'opens the home directory and matches the spillover text', ->
          local prompt, text
          command_line\write_spillover 'matchthis'
          within_activity interact.select_file, ->
            prompt = command_line.prompt
            text = command_line.text
          assert.same "~#{pathsep}", prompt
          assert.same 'matchthis', text

      context 'when spillover is an absolute path', ->
        it 'opens the closest valid directory', ->
          local prompt, text
          command_line\write_spillover tostring(tmpdir / 'matchthis')
          within_activity interact.select_file, ->
            prompt = command_line.prompt
            text = command_line.text
          assert.same tostring(tmpdir)..pathsep, File.expand_path prompt
          assert.same 'matchthis', text

      context 'when spillover is a directory path that exists', ->
        before_each ->
          File.mkdir tmpdir / 'subdir'

        it 'opens the directory when specified with a trailing "/"', ->
          local prompt, text
          command_line\write_spillover tostring(tmpdir / 'subdir') .. '/'
          within_activity interact.select_file, ->
            prompt = command_line.prompt
            text = command_line.text
          assert.same tostring(tmpdir / 'subdir')..pathsep, File.expand_path prompt
          assert.same '', text

        it 'opens the parent when specified without any trailing "/"', ->
          local prompt, text
          command_line\write_spillover tostring(tmpdir / 'subdir')
          within_activity interact.select_file, ->
            prompt = command_line.prompt
            text = command_line.text
          assert.same tostring(tmpdir)..pathsep, File.expand_path prompt
          assert.same 'subdir', text

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
        within_activity interact.select_file, ->
          command_line\write tostring(tmpdir) .. '/'
          items = get_ui_list_widget_column(2)
        assert.same { 'x.b', 'x.c' }, items

      it 'shows a hidden file after its exact name is entered', ->
        local items
        within_activity interact.select_file, ->
          command_line\write tostring(tmpdir) .. '/'
          command_line\write 'x.a'
          command_line\clear!
          command_line\write ''
          items = get_ui_list_widget_column(2)
        assert.same { 'x.b', 'x.c', 'x.a' }, items

    context 'in subtree mode', ->
      it 'shows files and directories in the subtree', ->
        files = { 'ab1', "ab2#{pathsep}", "ab2#{pathsep}xy", "ef#{pathsep}",
                  "ef#{pathsep}gh#{pathsep}", "ef#{pathsep}gh#{pathsep}ab4" }
        for name in *files
          f = tmpdir / name
          if name\ends_with pathsep
            f\mkdir!
          else
            f.contents = 'a'

        command_line\write_spillover tostring(tmpdir) .. '/'

        local items, items2
        within_activity (-> interact.select_file(show_subtree: true)), ->
          items = get_ui_list_widget_column(2)
          command_line\write 'ab'
          items2 = get_ui_list_widget_column(2)

        assert.same files, items
        expected = {'ab1', "ab2#{pathsep}", "ab2#{pathsep}xy",
                    "ef#{pathsep}gh#{pathsep}ab4"}
        assert.same expected, items2


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
      within_activity interact.select_directory, ->
        command_line\write tostring(tmpdir) .. '/'
        items = get_ui_list_widget_column(2)

      assert.same { ".#{pathsep}", "dir1#{pathsep}", "dir2#{pathsep}" }, items
