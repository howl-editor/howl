glib = require 'ljglibs.glib'
import config from howl
import File from howl.io
import markup from howl.ui
import Matcher from howl.util

append = table.insert
separator = File.separator

howl.config.define
  name: 'hidden_file_extensions'
  description: 'File extensions that determine which files should be hidden in file selection lists'
  scope: 'global'
  type_of: 'string_list'
  default: {'a', 'bc', 'git', 'hg', 'o', 'pyc', 'so'}

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
  return ".#{separator}" if file == base_directory
  rel_path = file\relative_to_parent(base_directory)
  return is_directory and rel_path .. separator or rel_path

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

subtree_matcher = (root, files=nil) ->
  unless files
    files = root\find sort: true

  paths = {}

  for f in *files
    is_directory = f.is_directory
    if is_directory continue
    append paths, display_name(f, is_directory, root)

  return Matcher paths, reverse: true

return { :file_matcher, :get_cwd, :get_dir_and_leftover, :subtree_matcher }
