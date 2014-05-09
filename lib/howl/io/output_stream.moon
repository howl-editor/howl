dispatch = howl.dispatch
{:UnixOutputStream} = require 'ljglibs.gio'

class OutputStream
  new: (fd) =>
    @stream = UnixOutputStream fd

  write: (contents) =>
    handle = dispatch.park 'input-stream-write'

    @stream\write_async contents, nil, (status, ret, err_code) ->
      if status
        dispatch.resume handle, ret
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"

    dispatch.wait handle

  close: => @stream\close!
