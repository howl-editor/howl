-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, mode, Buffer from howl
import highlight from howl.ui
import Matcher from howl.util

get_buffer_for_file = (file, local_buffers) ->
  for buffer in *app.buffers
    return buffer if buffer.file == file

  buffer = local_buffers[file.path]
  return buffer if buffer

  buffer = Buffer mode.for_file file
  buffer.file = file
  buffer.title = 'Preview: '..buffer.title
  local_buffers[file.path] = buffer
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
    local_buffers = {}

    on_selection_change = opts.on_selection_change
    opts.on_selection_change = (selection, text, items) ->
      if selection
        buffer = selection.buffer or get_buffer_for_file selection.file, local_buffers
        editor.buffer = buffer
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
