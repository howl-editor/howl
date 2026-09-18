-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

dispatch = howl.dispatch
{:UnixOutputStream} = require 'ljglibs.gio'
{:PropertyObject} = howl.util.moon

class OutputStream extends PropertyObject
  -- Accepts a file descriptor or an already-constructed gio output stream, so a
  -- socket connection's output stream can be used directly. Mirrors InputStream.
  new: (stream, @cancellable) =>
    @stream = type(stream) == 'number' and UnixOutputStream(stream) or stream
    super!

  @property is_closed: get: => @stream.is_closed

  -- g_output_stream_write_async may write fewer bytes than asked, so loop until
  -- everything is out rather than silently truncating.
  write: (contents) =>
    total = #contents
    return 0 if total == 0
    written = 0

    while written < total
      handle = dispatch.park 'output-stream-write'
      remaining = written == 0 and contents or contents\sub(written + 1)

      @stream\write_async remaining, nil, ((status, ret, err_code) ->
        if status
          dispatch.resume handle, ret
        else
          dispatch.resume_with_error handle, "#{ret} (#{err_code})"), @cancellable

      n = dispatch.wait handle
      n = tonumber(n) or 0
      error 'output stream accepted no data', 2 if n <= 0
      written += n

    written

  flush: =>
    handle = dispatch.park 'output-stream-flush'

    @stream\flush_async (status, ret, err_code) ->
      if status
        dispatch.resume handle, ret
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"

    dispatch.wait handle


  close: =>
    return if @stream.is_closed
    handle = dispatch.park 'output-stream-close'

    @stream\close_async (status, ret, err_code) ->
      if status
        dispatch.resume handle
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"

    dispatch.wait handle
