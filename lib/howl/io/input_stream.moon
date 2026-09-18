-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

dispatch = howl.dispatch
glib = require 'ljglibs.glib'
{:UnixInputStream} = require 'ljglibs.gio'
{:PropertyObject} = howl.util.moon
append = table.insert

class InputStream extends PropertyObject
  -- An optional cancellable makes reads abortable, which is what lets a caller
  -- impose a deadline (see howl.io.http).
  new: (@stream, @priority = glib.PRIORITY_LOW, @cancellable) =>
    @stream = UnixInputStream(@stream) if type(@stream) == 'number'
    super!

  @property is_closed: get: => @stream.is_closed

  read: (num = 4096) =>
    handle = dispatch.park 'input-stream-read'

    @stream\read_async num, @priority, ((status, ret, err_code) ->
      if status
        dispatch.resume handle, ret
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"), @cancellable

    dispatch.wait handle

  read_async: (num = 4096, handler) =>
    @stream\read_async num, @priority, handler, @cancellable

  read_all: =>
    contents = {}
    read = @read 8092
    while read
      append contents, read
      read = @read 8092

    table.concat contents

  close: =>
    return if @stream.is_closed
    handle = dispatch.park 'input-stream-close'

    @stream\close_async ((status, ret, err_code) ->
      if status
        dispatch.resume handle
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"), @cancellable

    dispatch.wait handle
