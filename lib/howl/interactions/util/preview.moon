-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, Buffer, mode from howl

new_buffer = (title, text, buffer_mode = {}) ->
  buffer = Buffer buffer_mode
  buffer.collect_revisions = false
  buffer.title = title
  buffer.text = text
  buffer.read_only = true
  buffer.data.is_preview = true
  buffer

nr_lines = (text) ->
  count = 0
  start = 1
  while true
    pos = text\find('[\r\n]', start)
    if not pos
      return count + 1

    start = pos + 1
    if text\sub(start, start) == '\n' and text\sub(pos, pos) == '\r'
      start += 1

    count += 1

get_preview_buffer = (file, line) ->
  if file.is_directory
    return new_buffer "Directory: #{file.basename}", file.path

  unless file.is_regular
    return new_buffer "No preview: #{file.basename}", "Preview not available for #{file.type} file."

  buffer_mode = nil
  title = file.basename
  ok, text = pcall -> file\open 'r', (fh) ->
    s = fh\read 8192
    return s unless s and line and line > nr_lines(s)
    -- we're looking for a specific line, but didn't find it in the first 8kB
    -- let's try a little harder, but not too much since we don't want slow
    -- things down
    more = fh\read 16384
    if more
      s ..= more

    s

  if ok
    size = file.size
    title = "#{title} (~#{math.floor(size / 1024)}KB)"
    if size == 0 or text.is_valid_utf8
      title = "Preview: #{title}"
      buffer_mode = mode.for_file file
    else
      title = "No Preview: #{title}"
      text = 'Preview not available.'
  else
    title = "No Preview: #{title}"

  new_buffer title, text or '', buffer_mode

(opts = {}) ->
  open_buffers = opts.only_previews and {} or
    { b.file.path, b for b in *app.buffers when b.file }

  {
    get_buffer: (file, line) =>
      buf = open_buffers[file.path]
      if buf
        is_preview = buf.data.is_preview
        if not line or not is_preview or #buf.lines >= line
          return buf

      buf = get_preview_buffer(file, line)
      open_buffers[file.path] = buf
      buf
  }
