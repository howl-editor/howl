import app from lunar
import Matcher from lunar.completion

buffer_dir = (buffer) ->
  buffer.file and tostring(buffer.file.parent) or '(none)'

class BufferInput
  new: (readline) =>
    buffers = [ { b.title, buffer_dir(b) } for b in *app.buffers ]
    @matcher = Matcher buffers, true, true, true

  should_complete: => true

  complete: (text) =>
    completion_options = list: headers: { 'Buffer', 'Directory' }
    return self.matcher(text), completion_options

  value_for: (title) =>
    for buffer in *app.buffers
      return buffer if buffer.title == title

lunar.inputs.register 'buffer', BufferInput
return BufferInput
