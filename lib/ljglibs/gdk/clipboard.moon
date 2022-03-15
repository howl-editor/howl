-- Copyright 2021 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
{:catch_error, :g_string} = require 'ljglibs.glib'
-- glib = require 'ljglibs.glib'
callbacks = require 'ljglibs.callbacks'
-- require 'ljglibs.gtk.selection_data'
gio = require 'ljglibs.gio'

-- C, ffi_cast = ffi.C, ffi.cast
C  = ffi.C

jit.off true, true

-- clear_funcs = setmetatable {}, __mode: 'v'

-- clipboard_clear_func = ffi.cast 'GVCallback2', (clipboard, data) ->
--   data = tonumber ffi.cast('gint', data)
--   clear_handler = clear_funcs[data]
--   if clear_handler
--     clear_handler clipboard

-- clipboard_get_func = ffi.cast 'GtkClipboardGetFunc', callbacks.void4

core.define 'GdkClipboard < GObject', {
  get: (atom) -> C.gdk_clipboard_get atom

  properties: {
    local: 'gboolean'
  }

  read_text_async: (callback) =>
    local handle

    handler = (source, res) ->
      print "in gdk cb: #{res}"
      callbacks.unregister handle
      callback res

      -- status, res = pcall ->
      --   g_string catch_error C.gdk_clipboard_read_text_finish, @, res

      -- -- text = g_string catch_error C.gdk_clipboard_read_text_finish, @, res
      -- -- print "in gdk cb text: #{text}"
      -- print "status: #{status}, ret: #{res}"
      -- callback res
      -- callback text

    handle = callbacks.register handler, 'clipboard-read-text-async'
    C.gdk_clipboard_read_text_async @, nil, gio.async_ready_callback, callbacks.cast_arg(handle.id)

  read_text_finish: (res) =>
    g_string catch_error C.gdk_clipboard_read_text_finish, @, res

  set_text: (text) => C.gdk_clipboard_set_text @, text, #text


  -- clear: => C.gdk_clipboard_clear @
  -- store: => C.gdk_clipboard_store @
  -- wait_for_text: => g_string C.gdk_clipboard_wait_for_text @

  -- request_text: (callback) =>
  --   self = @
  --   local cb_handle

  --   handler = (clipboard, text) ->
  --     callbacks.unregister cb_handle
  --     text = text != nil and ffi.string(text) or nil
  --     callback self, text

  --   cb_handle = callbacks.register handler, 'clipboard-request-text'
  --   C.gdk_clipboard_request_text @, ffi.cast('GtkClipboardTextReceivedFunc', callbacks.void3), callbacks.cast_arg(cb_handle.id)

  -- set: (targets, nr_targets, get_func, clear_func) =>
  --   return unless nr_targets > 0

  --   local get_handle

  --   handler = (clipboard, selection_data, info) ->
  --     selection_data = ffi_cast('GtkSelectionData *', selection_data)
  --     val = get_func @
  --     if val
  --       selection_data\set_text val

  --   get_handle = callbacks.register handler, 'clipboard-get-func'
  --   clear_funcs[get_handle.id] = clear_func

  --   status = C.gdk_clipboard_set_with_data @,
  --     targets,
  --     nr_targets,
  --     clipboard_get_func,
  --     clipboard_clear_func,
  --     callbacks.cast_arg(get_handle.id)

  --   status != 0

  -- set_can_store: (targets, nr_targets) =>
  --   C.gdk_clipboard_set_can_store @, targets, nr_targets
}
