-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

dispatch = howl.dispatch
glib = require 'ljglibs.glib'
{:UnixInputStream} = require 'ljglibs.gio'
{:PropertyObject} = howl.aux.moon
append = table.insert

class InputStream extends PropertyObject
  new: (@stream, @priority = glib.PRIORITY_LOW) =>
    @stream = UnixInputStream(@stream) if type(@stream) == 'number'
    super!

  @property is_closed: get: => @stream.is_closed

  read: (num = 4096) =>
    handle = dispatch.park 'input-stream-read'

    @stream\read_async num, @priority, (status, ret, err_code) ->
      if status
        dispatch.resume handle, ret
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"

    dispatch.wait handle

  read_async: (num = 4096, handler) =>
    @stream\read_async num, @priority, handler

  read_all: =>
    contents = {}
    read = @read 8092
    while read
      append contents, read
      read = @read 8092

    table.concat contents

  close: =>
    handle = dispatch.park 'input-stream-close'

    @stream\close_async (status, ret, err_code) ->
      if status
        dispatch.resume handle
      else
        dispatch.resume_with_error handle, "#{ret} (#{err_code})"

    dispatch.wait handle
