-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app from howl
import Matcher from howl.util

buffer_dir = (buffer) ->
  buffer.file and tostring(buffer.file.parent) or '(none)'

buffer_status = (buffer) ->
  stat = if buffer.modified then '*' else ''
  stat ..= '[modified on disk]' if buffer.modified_on_disk
  stat

load_matcher = ->
  buffers = [ { b.title, buffer_status(b), buffer_dir(b) } for b in *app.buffers ]
  Matcher buffers

class BufferInput
  should_complete: -> true
  close_on_cancel: -> true

  complete: (text) =>
    @matcher = load_matcher! unless @matcher
    completion_options = title: 'Buffers', list: column_styles: { 'string', 'operator', 'comment' }

    return self.matcher(text), completion_options

  value_for: (title) =>
    for buffer in *app.buffers
      return buffer if buffer.title == title

    with app\new_buffer!
      .title = title

howl.inputs.register {
  name: 'buffer',
  description: 'Returns a Buffer, existing or new',
  factory: BufferInput
}

return BufferInput
