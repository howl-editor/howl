-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, mode, Buffer from howl
import highlight from howl.ui
import Matcher from howl.util

get_preview_buffer = (file, preview_buffers) ->
  for buffer in *app.buffers
    return buffer if buffer.file == file

  buffer = preview_buffers[file.path]
  return buffer if buffer

  buffer = Buffer mode.for_file file
  title = file.basename
  local contents
  ok, result = pcall -> contents = file\read 8192

  if ok
    size = file.size
    title ..= ' (~'..tostring(math.floor(size / 1024))..'KB)'
    if size == 0 or contents.is_valid_utf8
      buffer.title = "Preview: #{title}"
      buffer.text = contents or ''
    else
      buffer.title = "No Preview: #{title}"
      buffer.text = 'Preview not available.'
  else
    buffer.title = "No Preview: #{title}"
    buffer.text = result

  buffer.read_only = true
  preview_buffers[file.path] = buffer
  return buffer

interact.register
  name: 'select_location'
  description: 'Selection list for locations - a location consists of a file (or buffer) and line number'
  handler: (opts) ->
    opts = moon.copy opts
    editor = opts.editor or app.editor
    buffer = editor.buffer
    orig_buffer = buffer
    orig_line_at_top = editor.line_at_top
    preview_buffers = {}

    if howl.config.preview_files or opts.force_preview
      on_selection_change = opts.on_selection_change
      opts.on_selection_change = (selection, text, items) ->
        if selection
          buffer = selection.buffer or get_preview_buffer selection.file, preview_buffers
          editor\preview buffer
          if selection.line_nr
            editor.line_at_center = selection.line_nr

        if on_selection_change
          on_selection_change selection, text, items

    result = interact.select opts
    if editor.buffer != orig_buffer
      editor.buffer = orig_buffer
    unless result
      editor.line_at_top = orig_line_at_top

    return result
