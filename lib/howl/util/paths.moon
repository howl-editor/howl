glib = require 'ljglibs.glib'
{:activities, :config} = howl
{:File} = howl.io
{:icon, :StyledText} = howl.ui
{:Matcher} = howl.util

append = table.insert
separator = File.separator

howl.config.define
  name: 'hidden_file_extensions'
  description: 'File extensions that determine which files should be hidden in file selection lists'
  scope: 'global'
  type_of: 'string_list'
  default: {'a', 'bc', 'git', 'hg', 'o', 'pyc', 'so'}

howl.config.define
  name: 'file_icons'
  description: 'Whether file and directory icons are displayed'
  scope: 'global'
  type_of: 'boolean'
  default: true

get_cwd = ->
  buffer = howl.app.editor and howl.app.editor.buffer
  directory = buffer and (buffer.file and buffer.file.parent or buffer.directory)
  return directory or File glib.get_current_dir!

should_hide = (file) ->
  extensions = config.hidden_file_extensions
  return false unless extensions
  file_ext = file.extension

  for ext in *extensions
    if file_ext == ext
      return true

  return false

display_name = (file, is_directory, base_directory) ->
  if file == base_directory
    return StyledText(".#{separator}", 'directory')
  rel_path = file\relative_to_parent(base_directory)
  if is_directory
    return StyledText(rel_path .. separator, 'directory')
  else
    return StyledText(rel_path, 'filename')

display_icon = (is_directory) ->
  is_directory and icon.get('directory', 'directory') or icon.get('file', 'filename')

get_dir_and_leftover = (path) ->
  if not path or path.is_blank or not File.is_absolute path
    directory = File.home_dir

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

    break if closest_dir.is_directory

    path = path\sub 1, -2
    unmatched = separator .. unmatched

    break unless pos

  if closest_dir
    return closest_dir, unmatched

  return File(glib.get_current_dir!).root_dir, path

file_matcher = (files, directory, allow_new=false) ->
  children = {}
  hidden_by_config = {}

  for file in *files
    is_directory = file.is_directory
    name = display_name(file, is_directory, directory)

    if should_hide file
      hidden_by_config[file.basename] = {
        StyledText(tostring(name), 'comment'),
        StyledText('[hidden]', 'comment'),
        :file
        name: tostring(name)
        :is_directory,
      }
    else
      append children, {
        name
        :file
        :is_directory,
        name: tostring(name)
        is_hidden: file.is_hidden
      }

  table.sort children, (f1, f2) ->
    d1, d2 = f1.is_directory, f2.is_directory
    h1, h2 = f1.is_hidden, f2.is_hidden
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
    if config.file_icons
      for item in *matches
        unless item.has_icon
          append item, 1, display_icon(item.is_directory)
          item.has_icon = true
    if not text or text.is_blank or not allow_new
      return matches

    for item in *matches
      if item.name == text or item.name == text..separator
        return matches

    append matches, {
      text,
      StyledText('[New]', 'keyword')
      file: directory / text
      name: text
      is_new: true
    }
    if config.file_icons
      append matches[#matches], 1, icon.get('file-new', 'filename')

    return matches

subtree_matcher = (files, directory, opts={}) ->
  loader = ->
    paths = {}

    for file in *files
      continue if should_hide file
      is_directory = file.is_directory
      continue if opts.exclude_directories and is_directory
      name = display_name(file, is_directory, directory)
      if config.file_icons
        append paths, {
          display_icon(is_directory)
          name
          :file
          name: tostring(name)
        }
      else
        append paths, {
          name
          :file
          name: tostring(name)
        }

    return Matcher(paths, reverse: true)

  activities.run {
    title: "Loading files from '#{directory}'"
    status: -> "Preparing #{#files} paths for selection.."
    preempt: true
  }, loader

subtree_reader = (directory, opts={}) ->
  files_found = 0
  cancel = false

  activities.run {
    title: "Scanning '#{directory}'"
    status: -> "Reading files.. (#{files_found} files read)"
    cancel: -> cancel = true
  }, ->
    directory\find
      sort: true
      filter: (file) -> should_hide(file) or opts.filter and opts.filter(file)
      on_enter: (dir, files) ->
        files_found = #files
        return 'break' if cancel

return { :file_matcher, :get_cwd, :get_dir_and_leftover, :subtree_matcher, :subtree_reader }
