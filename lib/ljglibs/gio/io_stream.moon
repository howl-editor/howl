-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

glib = require 'ljglibs.glib'
ffi = require 'ffi'
core = require 'ljglibs.core'
gio = require 'ljglibs.gio'
callbacks = require 'ljglibs.callbacks'
jit = require 'jit'
require 'ljglibs.cdefs.gio'
require 'ljglibs.gio.input_stream'
require 'ljglibs.gio.output_stream'
{:ref_ptr} = require 'ljglibs.gobject'

{:catch_error, :get_error} = glib
C = ffi.C

IOStream = core.define 'GIOStream < GObject', {

  properties: {
    -- transfer-none accessors, so take a reference rather than ownership
    input_stream: => ref_ptr C.g_io_stream_get_input_stream @
    output_stream: => ref_ptr C.g_io_stream_get_output_stream @
    is_closed: => C.g_io_stream_is_closed(@) != 0
  }

  close: (cancellable) => catch_error C.g_io_stream_close, @, cancellable

  close_async: (cancellable, callback) =>
    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      status, ret, err_code, domain = get_error C.g_io_stream_close_finish, @, res
      if not status
        callback false, ret, err_code, domain
      else
        callback true

    handle = callbacks.register handler, 'io-stream-close-async'
    C.g_io_stream_close_async @, 0, cancellable, gio.async_ready_callback, callbacks.cast_arg(handle.id)
}

jit.off IOStream.close_async

IOStream
