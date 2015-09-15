-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact, mode, Buffer from howl
import preview from howl.interactions.util
import highlight from howl.ui
import Matcher from howl.util

interact.register
  name: 'select_location'
  description: 'Selection list for locations - a location consists of a file (or buffer) and line number'
  handler: (opts) ->
    opts = moon.copy opts
    editor = opts.editor or app.editor
    buffer = editor.buffer

    if howl.config.preview_files or opts.force_preview
      on_change = opts.on_change
      opts.on_change = (selection, text, items) ->
        if selection
          buffer = selection.buffer or preview.get_preview_buffer selection.file
          editor\preview buffer
          if selection.line_nr
            editor.line_at_center = selection.line_nr

        if on_change
          on_change selection, text, items

    result = interact.select opts
    editor\cancel_preview!

    return result
