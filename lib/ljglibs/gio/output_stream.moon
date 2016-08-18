-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
ffi = require 'ffi'
core = require 'ljglibs.core'
gio = require 'ljglibs.gio'
callbacks = require 'ljglibs.callbacks'
jit = require 'jit'

import catch_error, get_error from glib

C = ffi.C
ffi_new, ffi_cast = ffi.new, ffi.cast
const_void_p = ffi.typeof 'const void *'

OutputStream = core.define 'GOutputStream < GObject', {

  properties: {
    has_pending: => C.g_output_stream_has_pending(@) != 0
    is_closed: => C.g_output_stream_is_closed(@) != 0
    is_closing: => C.g_output_stream_is_closing(@) != 0
  }

  close: => catch_error C.g_output_stream_close, @, nil
  flush: => catch_error C.g_output_stream_flush, @, nil

  write_all: (data, count = #data) =>
    return if count <= 0
    written = ffi_new 'gsize[1]'
    catch_error C.g_output_stream_write_all, @, ffi_cast(const_void_p, data), count, written, nil

  write_async: (data, count = #data, callback) =>
    if count <= 0
      callback true, 0
      return

    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      status, ret, err_code = get_error C.g_output_stream_write_finish, @, res
      if not status
        callback false, ret, err_code
      else
        callback true, tonumber ret

    handle = callbacks.register handler, 'output-write-async'
    C.g_output_stream_write_async @, ffi_cast(const_void_p, data), count, 0, nil, gio.async_ready_callback, callbacks.cast_arg(handle.id)

  close_async: (callback) =>
    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      status, ret, err_code = get_error C.g_output_stream_close_finish, @, res
      if not status
        callback false, ret, err_code
      else
        callback true

    handle = callbacks.register handler, 'output-close-async'
    C.g_output_stream_close_async @, 0, nil, gio.async_ready_callback, callbacks.cast_arg(handle.id)
 }

jit.off OutputStream.write_async
jit.off OutputStream.close_async

OutputStream
