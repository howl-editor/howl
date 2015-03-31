-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, config, interact from howl
import File from howl.io
import Window from howl.ui

file_selection = require 'howl.interactions.file_selection'

describe 'file_selection', ->
  local tmpdir, command_line

  before_each ->
    app.window = Window!
    app.window\realize!
    command_line = app.window.command_line

    tmpdir = File.tmpdir!

  after_each ->
    tmpdir\rm_r!

  it "registers interactions", ->
    assert.not_nil interact.select_file
    assert.not_nil interact.select_file_in_project
    assert.not_nil interact.select_directory

  describe 'parse_path', ->
    it 'returns the home dir for empty input', ->
      assert.same {file_selection.home_dir!, ''}, {file_selection.parse_path ''}

    it 'returns the root directory for "/"', ->
      assert.same {file_selection.root_dir!, ''}, {file_selection.parse_path '/'}

    it 'returns the matched path and unmatched parts of a path', ->
      assert.same {tmpdir, 'unmatched'}, {file_selection.parse_path tostring(tmpdir / 'unmatched')}

    it 'unmatched part can contain slashes', ->
      assert.same {tmpdir, 'unmatched/no/such/file'}, {file_selection.parse_path tostring(tmpdir / 'unmatched/no/such/file')}

    context 'is given a non absolute path', ->
      it 'uses the home dir as the base path', ->
        assert.same {file_selection.home_dir!, 'unmatched-asdf98y23903943masgb sdf'}, {file_selection.parse_path 'unmatched-asdf98y23903943masgb sdf'}

  describe 'interact.select_file', ->
    it 'opens the home directory by default', ->
      local prompt
      within_activity interact.select_file, ->
        prompt = command_line.prompt
      assert.same '~/', prompt

    it 'typing a path opens the closest parent', ->
      prompts = {}
      within_activity interact.select_file, ->
        command_line\write tostring(tmpdir)
        table.insert prompts, command_line.prompt
      assert.same {tostring(tmpdir.parent) .. '/'}, prompts

    it 'typing "/" after a directory name opens the directory', ->
      local prompt
      within_activity interact.select_file, ->
        command_line\write tostring(tmpdir) .. '/'
        prompt = command_line.prompt
      assert.same tostring(tmpdir) .. '/', prompt

    it 'typing "../" switches to the parent of the current directory', ->
      prompts = {}
      within_activity interact.select_file, ->
        command_line\write tostring(tmpdir) .. '/'
        table.insert prompts, command_line.prompt
        command_line\write tostring(tmpdir) .. '../'
        table.insert prompts, command_line.prompt
      assert.same {tostring(tmpdir) .. '/', tostring(tmpdir.parent) .. '/'}, prompts

    it 'typing "/" without any preceeding text changes to home directory', ->
      local prompt
      within_activity interact.select_file, ->
        command_line\write '/'
        prompt = command_line.prompt
      assert.same '/', prompt

    it 'shows files matching entered text in the current directory', ->
      files = { 'ab1', 'ab2', 'bc1' }
      for f in *files
        f = tmpdir / f
        f.contents = 'a'

      local items, items2
      within_activity interact.select_file, ->
        command_line\write tostring(tmpdir) .. '/'
        items = get_list_items(1)

        command_line\write 'ab'
        items2 = get_list_items(1)

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
          assert.same '~/', prompt
          assert.same 'matchthis', text

      context 'when spillover is an absolute path', ->
        it 'opens the specified path', ->
          local prompt, text
          command_line\write_spillover tostring(tmpdir / 'matchthis')
          within_activity interact.select_file, ->
            prompt = command_line.prompt
            text = command_line.text
          assert.same tostring(tmpdir)..'/', prompt
          assert.same 'matchthis', text

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
          items = get_list_items!
        assert.same { 'x.b', 'x.c' }, items

      it 'shows a hidden file after its exact name is entered', ->
        local items
        within_activity interact.select_file, ->
          command_line\write tostring(tmpdir) .. '/'
          command_line\write 'x.a'
          command_line\clear!
          command_line\write ''
          items = get_list_items!
        assert.same { 'x.b', 'x.c', 'x.a' }, items

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
        items = get_list_items(1)

      assert.same { './', 'dir1/', 'dir2/' }, items
