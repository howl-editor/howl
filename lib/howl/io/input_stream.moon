dispatch = howl.dispatch
{:UnixInputStream} = require 'ljglibs.gio'

class InputStream
  new: (fd) =>
    @stream = UnixInputStream fd

  read: (num) =>
    handle = dispatch.park 'input-stream-read'

    @stream\read_async nil, (status, ret, err_code) ->
      if status
        dispatch.resume handle, ret
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"

    dispatch.wait handle
