-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

dispatch = howl.dispatch
{:UnixInputStream} = require 'ljglibs.gio'
{:PropertyObject} = howl.aux.moon

class InputStream extends PropertyObject
  new: (fd) =>
    @stream = UnixInputStream fd
    super!

  @property is_closed: get: => @stream.is_closed

  read: (num) =>
    handle = dispatch.park 'input-stream-read'

    @stream\read_async nil, (status, ret, err_code) ->
      if status
        dispatch.resume handle, ret
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"

    dispatch.wait handle

  close: =>
    handle = dispatch.park 'input-stream-close'

    @stream\close_async (status, ret, err_code) ->
      if status
        dispatch.resume handle
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"

    dispatch.wait handle
