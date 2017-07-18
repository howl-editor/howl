-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
glib = require 'ljglibs.glib'
callbacks = require 'ljglibs.callbacks'
require 'ljglibs.gtk.selection_data'

C, ffi_cast = ffi.C, ffi.cast

jit.off true, true

clear_funcs = setmetatable {}, __mode: 'v'

clipboard_clear_func = ffi.cast 'GVCallback2', (clipboard, data) ->
  data = tonumber ffi.cast('gint', data)
  clear_handler = clear_funcs[data]
  if clear_handler
    clear_handler clipboard

clipboard_get_func = ffi.cast 'GtkClipboardGetFunc', callbacks.void4

core.define 'GtkClipboard < GObject', {
  get: (atom) -> C.gtk_clipboard_get atom

  properties: {
    text:
      get: => @wait_for_text!
      set: (text) => @set_text text
  }

  clear: => C.gtk_clipboard_clear @
  store: => C.gtk_clipboard_store @
  set_text: (text) => C.gtk_clipboard_set_text @, text, #text
  wait_for_text: => glib.g_string C.gtk_clipboard_wait_for_text @

  request_text: (callback) =>
    self = @
    local cb_handle

    handler = (clipboard, text) ->
      callbacks.unregister cb_handle
      text = text != nil and ffi.string(text) or nil
      callback self, text

    cb_handle = callbacks.register handler, 'clipboard-request-text'
    C.gtk_clipboard_request_text @, ffi.cast('GtkClipboardTextReceivedFunc', callbacks.void3), callbacks.cast_arg(cb_handle.id)

  set: (targets, nr_targets, get_func, clear_func) =>
    return unless nr_targets > 0

    local get_handle

    handler = (clipboard, selection_data, info) ->
      selection_data = ffi_cast('GtkSelectionData *', selection_data)
      val = get_func @
      if val
        selection_data\set_text val

    get_handle = callbacks.register handler, 'clipboard-get-func'
    clear_funcs[get_handle.id] = clear_func

    status = C.gtk_clipboard_set_with_data @,
      targets,
      nr_targets,
      clipboard_get_func,
      clipboard_clear_func,
      callbacks.cast_arg(get_handle.id)

    status != 0

  set_can_store: (targets, nr_targets) =>
    C.gtk_clipboard_set_can_store @, targets, nr_targets
}
