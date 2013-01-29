import app from howl
import Matcher from howl.util

buffer_dir = (buffer) ->
  buffer.file and tostring(buffer.file.parent) or '(none)'

load_matcher = ->
  buffers = [ { b.title, buffer_dir(b) } for b in *app.buffers ]
  Matcher buffers

class BufferInput
  should_complete: => true

  complete: (text) =>
    @matcher = load_matcher! unless @matcher
    completion_options = title: 'Buffers'
    return self.matcher(text), completion_options

  value_for: (title) =>
    for buffer in *app.buffers
      return buffer if buffer.title == title

howl.inputs.register 'buffer', BufferInput
return BufferInput
