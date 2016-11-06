-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

dispatch = howl.dispatch
{:Win32OutputStream, :UnixOutputStream} = require 'ljglibs.gio'
{:PropertyObject} = howl.util.moon
{:platform} = howl.sys

class OutputStream extends PropertyObject
  new: (fd) =>
    @stream = platform.fd_to_stream Win32OutputStream, UnixOutputStream, fd
    super!

  @property is_closed: get: => @stream.is_closed

  write: (contents) =>
    return if #contents == 0
    handle = dispatch.park 'output-stream-write'

    @stream\write_async contents, nil, (status, ret, err_code) ->
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
