-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'

import app, clipboard, config, interact, log, Project from howl
import File from howl.io
import markup, style, ListWidget from howl.ui
import Matcher from howl.util

append = table.insert
separator = File.separator

style.define_default 'directory', 'key'
style.define_default 'filename', 'string'

howl.config.define
  name: 'hidden_file_extensions'
  description: 'File extensions that determine which files should be hidden in file selection lists'
  scope: 'global'
  type_of: 'string_list'
  default: {'a', 'bc', 'git', 'hg', 'o', 'pyc', 'so'}

home_dir = -> File glib.get_home_dir!

root_dir = (file) ->
  if not file
    return root_dir home_dir!
  while file.parent
    file = file.parent
  return file

display_name = (file, is_directory, base_directory) ->
  return ".#{separator}" if file == base_directory
  rel_path = file\relative_to_parent(base_directory)
  return is_directory and rel_path .. separator or rel_path

parse_path = (path) ->
  if not path or path.is_blank or not File.is_absolute path
    local directory
    if app.editor and app.editor.buffer
      file = app.editor.buffer.file
      directory = file.parent if file
    if not directory
      directory = home_dir!

    if not path or path.is_blank
      return directory, ''
    else
      path = tostring directory / path

  path = File.expand_path path
  root_marker = separator .. separator
  pos = path\rfind root_marker
  if pos
    path = path\sub pos + 1

  unmatched = ''
  local closest_dir
  while not path.is_empty
    pos = path\rfind(separator)
    if pos
      unmatched = path\sub(pos + 1) .. unmatched
      path = path\sub 1, pos
    closest_dir = File path
    if closest_dir.exists and closest_dir.is_directory
      break
    else
      path = path\sub 1, -2
      unmatched = separator .. unmatched
    if not pos
      break

  if closest_dir
    return closest_dir, unmatched

  return root_dir(File glib.get_current_dir!), path

should_hide = (file) ->
  extensions = config.hidden_file_extensions
  return false unless extensions
  file_ext = file.extension

  for ext in *extensions
    if file_ext == ext
      return true

  return false

file_matcher = (files, directory, allow_new=false) ->
  children = {}
  hidden_by_config = {}

  for c in *files
    is_directory = c.is_directory
    name = display_name(c, is_directory, directory)

    if should_hide c
      hidden_by_config[c.basename] = {
        markup.howl("<comment>#{name}</>"),
        markup.howl("<comment>[hidden]</>"),
        :name
        :is_directory,
      }
    else
      append children, {
        is_directory and markup.howl("<directory>#{name}</>") or name
        :name
        :is_directory,
        is_hidden: c.is_hidden
      }

  table.sort children, (f1, f2) ->
    d1, d2 = f1.is_directory, f2.is_directory
    h1, h2 = f1.is_hidden, f2.is_hidden
    return false if u1 and not u2
    return false if h1 and not h2
    return true if h2 and not h1
    return true if d1 and not d2
    return false if d2 and not d1
    f1.name < f2.name

  matcher = Matcher children

  return (text) ->
    hidden_exact_match = hidden_by_config[text]
    if hidden_exact_match
      append children, hidden_exact_match
      hidden_by_config[text] = nil
      matcher = Matcher children

    matches = moon.copy matcher(text)
    if not text or text.is_blank or not allow_new
      return matches

    for item in *matches
      if item.name == text or item.name == text..separator
        return matches

    append matches, {
      text,
      markup.howl '<keyword>[New]</>'
      name: text
      is_new: true
    }

    return matches

separator_count = (s) ->
  start = 1
  count = 0
  while start
    start = s\find separator, start, true
    if start
      break if start == #s
      count += 1
      start += 1
  count

sort_paths = (paths) ->
  table.sort paths, (a, b) ->
    a_count = separator_count a
    b_count = separator_count b
    return a_count < b_count if a_count != b_count
    a < b

subdirs = (directory) ->
  files = [c for c in *directory.children when c.is_directory]
  append files, directory\join '.'
  files

subtree_matcher = (root, files=nil) ->
  if not files
    files = root\find!

  paths = {}

  for f in *files
    is_directory = f.is_directory
    if is_directory continue
    append paths, display_name(f, is_directory, root)

  sort_paths paths
  return Matcher paths, reverse: true

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

    path = @command_line\pop_spillover! or ''

    if @command_line.directory
      path = tostring @command_line.directory / path

    directory, unmatched = parse_path path
    @_chdir directory, unmatched

  _chdir: (directory, text) =>
    @directory = directory
    matcher = file_matcher self.directory_reader(directory), directory, @opts.allow_new

    @list_widget.matcher = matcher
    @list_widget\update text

    basename = directory.short_path
    basename ..= separator if not basename\ends_with separator
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
      return false if not @command_line.text.is_empty
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

    return if not project

    matcher = project_matcher(project)

    selected_path = interact.select
      title: opts.title or project.root.path .. separator
      prompt: opts.prompt or ''
      :matcher
      columns: { {style: 'filename'} }

    if selected_path
      return project.root\join selected_path.selection

return {
  :file_matcher
  :parse_path
  :home_dir
  :root_dir
}
