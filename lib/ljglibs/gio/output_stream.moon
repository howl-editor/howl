-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

glib = require 'ljglibs.glib'
ffi = require 'ffi'
core = require 'ljglibs.core'
gio = require 'ljglibs.gio'
callbacks = require 'ljglibs.callbacks'
jit = require 'jit'

import catch_error, get_error from glib

C = ffi.C
ffi_string, ffi_new, ffi_cast = ffi.string, ffi.new, ffi.cast
buf_t = ffi.typeof 'unsigned char[?]'
const_void_p = ffi.typeof 'const void *'

OutputStream = core.define 'GOutputStream < GObject', {

  close: => catch_error C.g_output_stream_close, @, nil
  flush: => catch_error C.g_output_stream_flush, @, nil

  write_all: (data, count = #data) =>
    return if count <= 0
    written = ffi_new 'gsize[1]'
    catch_error C.g_output_stream_write_all, @, ffi_cast(const_void_p, data), count, written, nil

  write_async: (data, count = #data, callback) =>
    return if count <= 0
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
}

jit.off OutputStream.write_async
OutputStream
