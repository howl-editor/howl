-- Copyright 2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
{:catch_error, :g_string} = require 'ljglibs.glib'
callbacks = require 'ljglibs.callbacks'
gio = require 'ljglibs.gio'

C  = ffi.C

jit.off true, true

core.define 'GdkClipboard < GObject', {
  get: (atom) -> C.gdk_clipboard_get atom

  properties: {
    local: 'gboolean'
  }

  read_text_async: (callback) =>
    local handle

    handler = (source, res) ->
      callbacks.unregister handle
      callback res

    handle = callbacks.register handler, 'clipboard-read-text-async'
    C.gdk_clipboard_read_text_async @, nil, gio.async_ready_callback, callbacks.cast_arg(handle.id)

  read_text_finish: (res) =>
    g_string catch_error(C.gdk_clipboard_read_text_finish, @, res)

  set_text: (text) =>
    C.gdk_clipboard_set_text @, text, #text
}
