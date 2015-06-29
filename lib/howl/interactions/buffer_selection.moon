-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, interact from howl
import Matcher from howl.util

buffer_dir = (buffer) ->
  buffer.file and tostring(buffer.file.parent) or '(none)'

buffer_status = (buffer) ->
  stat = if buffer.modified then '*' else ''
  stat ..= '[modified on disk]' if buffer.modified_on_disk
  stat

get_buffers = (txt) ->
  m = Matcher [{buffer.title, buffer_status(buffer), buffer_dir(buffer), :buffer} for buffer in *app.buffers]
  return m(txt)

interact.register
  name: 'select_buffer'
  description: 'Selection list for buffers'
  handler: (opts={}) ->
    opts = moon.copy opts
    with opts
      .title or= 'Buffers'
      .matcher = get_buffers
      .columns = {
        {style: 'string'}
        {style: 'operator'}
        {style: 'comment'}
      }
      .keymap = {
        binding_for:
          ['close']: (current) ->
            if current.selection
              app\close_buffer current.selection.buffer
      }

    result = interact.select_location opts
    if result
      return result.selection.buffer
