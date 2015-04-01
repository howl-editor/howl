import Matcher from howl.util

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

    unless directory
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
    unless pos
      break

  if closest_dir
    return closest_dir, unmatched

  return root_dir(File glib.get_current_dir!), path

sort_paths = (paths) ->
  table.sort paths, (a, b) ->
    a_count = a\count File.separator
    b_count = b\count File.separator
    return a_count < b_count if a_count != b_count
    a < b

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
    files = root\find!

  paths = {}

  for f in *files
    is_directory = f.is_directory
    if is_directory continue
    append paths, display_name(f, is_directory, root)

  sort_paths paths
  return Matcher paths, reverse: true

return { :parse_path, :file_matcher }
