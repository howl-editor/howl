-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'

import app, clipboard, config, interact, log, Project from howl
import File from howl.io
import preview from howl.interactions.util
import icon, markup, style, ListWidget from howl.ui
import file_matcher, subtree_matcher, get_dir_and_leftover from howl.util.paths

append = table.insert
separator = File.separator

style.define_default 'directory', 'key'
style.define_default 'filename', 'string'
icon.define_default 'directory', 'font-awesome-folder'
icon.define_default 'file', 'font-awesome-file'
icon.define_default 'file-new', 'font-awesome-plus-circle'

subdirs = (directory) ->
  files = [c for c in *directory.children when c.is_directory]
  append files, directory\join '.'
  files

project_matcher = (project) -> subtree_matcher(project.root, project\files!)

get_project = ->
  if app.editor
    file = app.editor.buffer.file or app.editor.buffer.directory
    if file
      return Project.for_file file

class FileSelector
  run: (@finish, @opts={}) =>
    @directory_reader = @opts.directory_reader or (d) -> d.children
    @command_line = app.window.command_line
    @command_line.prompt = @opts.prompt or ''
    @command_line.title = @opts.title or 'File'

    @list_widget = ListWidget nil,
      never_shrink: true,
      on_selection_change: @\_preview
    @list_widget.max_height_request = math.floor app.window.allocated_height * 0.5
    if config.file_icons
      @list_widget.columns =  { {}, {style: 'filename'} }
    else
      @list_widget.columns =  { {style: 'filename'} }

    @command_line\add_widget 'completion_list', @list_widget

    parent = app.editor and app.editor.buffer and app.editor.buffer.file and app.editor.buffer.file.parent
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
    matcher = file_matcher self.directory_reader(directory), directory, @opts.allow_new

    @list_widget.matcher = matcher
    @list_widget\update text

    basename = directory.short_path
    basename ..= separator unless basename\ends_with separator
    @command_line.prompt = markup.howl "<directory>#{basename}</>"
    @command_line.text = text or ''

  _preview: (selection) =>
    return unless config.preview_files

    file = @directory / selection.name
    if file.exists
      app.editor\preview preview.get_preview_buffer file
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

  keymap:
    enter: =>
      app.editor\cancel_preview!
      name = @list_widget.selection and @list_widget.selection.name
      if not @allow_new and not name
        log.error 'Invalid path'
        return

      if name == ".#{separator}"
        @_submit @directory
        return

      path = @directory\join name

      if path.exists and path.is_directory
        @_chdir path
      else
        @_submit path

    backspace: =>
      return false unless @command_line.text.is_empty
      @_chdir @directory.parent if @directory.parent

    escape: =>
      app.editor\cancel_preview!
      self.finish!

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
      .directory_reader = subdirs
      .title or= 'Directory'

    interact.select_file opts

interact.register
  name: 'select_file_in_project'
  description: 'Selection list for all files in project'
  handler: (opts={}) ->
    project = opts.project or get_project!

    return unless project

    matcher = project_matcher(project)

    result = interact.select_location
      title: opts.title or project.root.path .. separator
      prompt: opts.prompt or ''
      :matcher
      columns: { {style: 'filename'} }

    if result
      return result.selection.file
