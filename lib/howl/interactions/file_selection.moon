-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, config, interact, log, Project from howl
import File from howl.io
import Preview from howl.interactions.util
import icon, markup, style, ListWidget from howl.ui
import file_matcher, subtree_matcher, subtree_reader, get_dir_and_leftover from howl.util.paths
{:Matcher} = howl.util

append = table.insert
separator = File.separator

style.define_default 'directory', 'key'
style.define_default 'filename', 'string'
icon.define_default 'directory', 'font-awesome-folder'
icon.define_default 'file', 'font-awesome-file'
icon.define_default 'file-new', 'font-awesome-plus-circle'

project_matcher = (project) ->
  subtree_matcher(project\files!, project.root, exclude_directories: true)

get_project = ->
  if app.editor
    file = app.editor.buffer.file or app.editor.buffer.directory
    if file
      return Project.for_file file

class FileSelector
  run: (@finish, @opts={}) =>
    @directory_reader = @opts.directory_reader or (d) -> d.children
    @subtree_reader = @opts.subtree_reader or subtree_reader
    @show_subtree = @opts.show_subtree
    @command_line = app.window.command_line
    @command_line.prompt = @opts.prompt or ''

    @list_widget = ListWidget nil,
      never_shrink: true,
      on_selection_change: @\_preview
    @list_widget.max_height_request = math.floor app.window.allocated_height * 0.5

    @command_line\add_widget 'completion_list', @list_widget

    buffer = app.editor and app.editor.buffer
    parent = buffer and buffer.directory or (buffer.file and buffer.file.parent)
    parent or= File.home_dir

    path = @command_line\pop_spillover!

    if path.is_empty
      path = tostring(parent) .. '/'
    else
      trailing = path\ends_with('/') and '/' or ''
      path = tostring parent / path
      if not path\ends_with '/'
        path ..= trailing

    directory, unmatched = get_dir_and_leftover path
    @_chdir directory, unmatched

  _chdir: (directory, text) =>
    @directory = directory
    local matcher
    if @show_subtree
      items, timed_out = self.subtree_reader(directory)
      matcher = subtree_matcher items, directory
      if timed_out
        @command_line.title = (@opts.title or 'File') .. ' (recursive, truncated)'
        log.warn 'File scan interrupted - truncated listing.'
      else
        @command_line.title = (@opts.title or 'File') .. ' (recursive)'
    else
      matcher = file_matcher self.directory_reader(directory), directory, @opts.allow_new
      @command_line.title = @opts.title or 'File'

    @list_widget.matcher = matcher
    @list_widget\update text

    basename = directory.short_path
    basename ..= separator unless basename\ends_with separator
    @command_line.prompt = markup.howl "<directory>#{basename}</>"
    @command_line.text = text or ''

  _preview: (selection) =>
    return unless config.preview_files
    @preview or= Preview!

    file = selection.file
    if file.exists
      app.editor\preview @preview\get_buffer file
    else
      app.editor\cancel_preview!

  on_update: (text) =>
    return if @submitting

    path = @directory.path .. '/' .. text
    directory, text = get_dir_and_leftover path

    if directory != @directory
      @_chdir directory, text
    else
      @list_widget\update text

  _submit: (path) =>
    @submitting = true
    if path == @directory
      @command_line.text = ''
    else
      @command_line.text = path.basename
    self.finish path

  _open: =>
    app.editor\cancel_preview!
    file = @list_widget.selection and @list_widget.selection.file
    name = @list_widget.selection and @list_widget.selection.name
    if not @opts.allow_new and (not file or not file.exists)
      log.error "Invalid path: #{file}"
      return

    if name == ".#{separator}"
      @_submit @directory
    elseif file.exists and file.is_directory
      @_chdir file
    else
      @_submit file

  keymap:
    enter: =>
      @_open!

    tab: =>
      count = 0
      for item in *@list_widget.items
        count += 1 unless item.is_new
      if count == 1
        -- open a unique completion
        if @list_widget.selection and not @list_widget.selection.is_new
          @_open!
      else
        @list_widget\select_next!
        -- if we land on the new entry, skip it by going forward again
        @list_widget\select_next! if @list_widget.selection.is_new

    shift_tab: =>
      @list_widget\select_prev!
      -- if we land on the new entry, skip it by going backward again
      @list_widget\select_prev! if @list_widget.selection.is_new

    backspace: =>
      return false unless @command_line.text.is_empty
      @_chdir @directory.parent if @directory.parent

    escape: =>
      app.editor\cancel_preview!
      self.finish!

    ctrl_s: =>
      @show_subtree = not @show_subtree
      @_chdir @directory

  help: {
    {
      key: 'ctrl_s'
      action: 'Toggle recursive search'
    }
  }

interact.register
  name: 'select_file'
  description: 'File browser based file selection'
  factory: FileSelector

interact.register
  name: 'select_directory'
  description: 'File browser based directory selection'
  handler: (opts={}) ->
    opts = moon.copy opts
    with opts
      .directory_reader = (directory) ->
        dirs = [child for child in *directory.children when child.is_directory]
        append dirs, 1, directory
        return dirs

      .subtree_reader = (directory) ->
        dirs, timed_out = subtree_reader directory, filter: (file) -> not file.is_directory
        append dirs, 1, directory
        return dirs, timed_out

      .title or= 'Directory'

    interact.select_file opts

interact.register
  name: 'select_file_in_project'
  description: 'Selection list for all files in project'
  handler: (opts={}) ->
    project = opts.project or get_project!

    return unless project

    matcher = project_matcher(project)
    explain = (search, text) -> Matcher.explain search, text, reverse: true

    result = interact.select_location
      title: opts.title or project.root.short_path .. separator
      prompt: opts.prompt or ''
      :matcher
      :explain

    if result
      return result.selection.file
