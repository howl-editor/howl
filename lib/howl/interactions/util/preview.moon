-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, Buffer, mode from howl

new_buffer = (title, text, mode = {}) ->
  buffer = Buffer mode
  buffer.title = title
  buffer.text = text
  buffer.read_only = true
  buffer

get_preview_buffer = (file) ->
  if file.is_directory
    return new_buffer "Directory: #{file.basename}", file.path

  unless file.is_regular
    return new_buffer "No preview: #{file.basename}", "Preview not available for #{file.type} file."

  buffer_mode = nil
  title = file.basename
  ok, text = pcall -> file\read 8192

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

  new_buffer title, text, buffer_mode

->
  open_buffers = { b.file.path, b for b in *app.buffers when b.file }
  {
    get_buffer: (file) =>
      open_buffer = open_buffers[file.path]
      open_buffer or get_preview_buffer(file)
  }
