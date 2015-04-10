-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'

import app, clipboard, interact, log, Project from howl
import File from howl.io
import markup, style, ListWidget from howl.ui
import file_matcher, subtree_matcher, parse_path from howl.util.paths

append = table.insert
separator = File.separator

style.define_default 'directory', 'key'
style.define_default 'filename', 'string'

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

    @list_widget = ListWidget nil, never_shrink: true
    @list_widget.max_height = math.floor app.window.allocated_height * 0.5
    @list_widget.columns =  { {style: 'filename'} }

    @command_line\add_widget 'completion_list', @list_widget

    parent = app.editor and app.editor.buffer and app.editor.buffer.file and app.editor.buffer.file.parent
    parent or= File.home_dir

    path = @command_line\pop_spillover!

    if path.is_empty
      path = tostring(parent) .. '/'
    else
      path = tostring parent / path

    directory, unmatched = parse_path path
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

  on_update: (text) =>
    path = @directory.path .. '/' .. text
    directory, text = parse_path path

    if directory != @directory
      @_chdir directory, text
    else
      @list_widget\update text

  keymap:
    enter: =>
      name = @list_widget.selection and @list_widget.selection.name
      if not @allow_new and not name
        log.error 'Invalid path'
        return

      if name == ".#{separator}"
        self.finish @directory
        return

      path = @directory\join name

      if path.exists and path.is_directory
        @_chdir path
      else
        @command_line.text = name
        self.finish path

    backspace: =>
      return false unless @command_line.text.is_empty
      @_chdir @directory.parent if @directory.parent

    escape: =>
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

    selected_path = interact.select
      title: opts.title or project.root.path .. separator
      prompt: opts.prompt or ''
      :matcher
      columns: { {style: 'filename'} }

    if selected_path
      return project.root\join selected_path.selection
