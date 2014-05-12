-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

gio = require 'ljglibs.gio'
glib = require 'ljglibs.glib'
ffi = require 'ffi'
core = require 'ljglibs.core'
callbacks = require 'ljglibs.callbacks'
jit = require 'jit'

import catch_error, get_error from glib

C = ffi.C
ffi_string, ffi_new = ffi.string, ffi.new
buf_t = ffi.typeof 'unsigned char[?]'

InputStream = core.define 'GInputStream < GObject', {

  properties: {
    has_pending: => C.g_input_stream_has_pending(@) != 0
    is_closed: => C.g_input_stream_is_closed(@) != 0
  }

  close: => catch_error C.g_input_stream_close, @, nil

  read: (count = 4096) =>
    return '' if count == 0
    buf = ffi_new buf_t, count
    read = catch_error C.g_input_stream_read, @, buf, count, nil
    return nil if read == 0
    ffi_string buf, read

  read_all: (count = 4096) =>
    return '' if count == 0
    buf = ffi_new buf_t, count
    read = ffi_new 'gsize[1]'
    catch_error C.g_input_stream_read_all, @, buf, count, read, nil
    return nil if read[0] == 0
    ffi_string buf, read[0]

  read_async: (count = 4096, callback) =>
    return '' if count == 0
    buf = ffi_new buf_t, count

    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      status, ret, err_code = get_error C.g_input_stream_read_finish, @, res
      if not status
        callback false, ret, err_code
      else
        read = ret
        val = read != 0 and ffi_string(buf, read) or nil
        callback true, val

    handle = callbacks.register handler, 'input-read-async'
    C.g_input_stream_read_async @, buf, count, 0, nil, gio.async_ready_callback, callbacks.cast_arg(handle.id)

  close_async: (callback) =>
    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      status, ret, err_code = get_error C.g_input_stream_close_finish, @, res
      if not status
        callback false, ret, err_code
      else
        callback true

    handle = callbacks.register handler, 'input-close-async'
    C.g_input_stream_close_async @, 0, nil, gio.async_ready_callback, callbacks.cast_arg(handle.id)
}

jit.off InputStream.read_async
InputStream
