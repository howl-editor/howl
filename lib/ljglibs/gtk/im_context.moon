-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
core = require 'ljglibs.core'
{:g_string} = require 'ljglibs.glib'
require 'ljglibs.cdefs.gtk'
require 'ljglibs.gobject.object'
gobject = require 'ljglibs.gobject'

signal = gobject.signal
C, ffi_string, ffi_new, ffi_gc = ffi.C, ffi.string, ffi.new, ffi.gc
pack, unpack = table.pack, table.unpack

GtkIMContext = ffi.typeof 'GtkIMContext *'

core.define 'GtkIMContext < GObject', {
  properties: {
    client_window:
      set: (win) => @set_client_window win

    use_preedit:
      set: (v) => @set_use_preedit v
  }

  set_client_window: (window) =>
    C.gtk_im_context_set_client_window @, window

  get_preedit_string: =>
    s_ptr_ptr = ffi_new 'gchar *[1]'
    pal_ptr_ptr = ffi_new 'PangoAttrList *[1]'
    cursor_ptr = ffi_new 'gint[1]'
    C.gtk_im_context_get_preedit_string @, s_ptr_ptr, pal_ptr_ptr, cursor_ptr
    str = g_string s_ptr_ptr[0]
    attr_list =  ffi_gc pal_ptr_ptr[0], C.pango_attr_list_unref
    cursor_pos = tonumber cursor_ptr[0]
    str, attr_list, cursor_pos

  filter_keypress: (event) =>
    C.gtk_im_context_filter_keypress(@, event) != 0

  focus_in: =>
    C.gtk_im_context_focus_in @

  focus_out: =>
    C.gtk_im_context_focus_out @

  set_use_preedit: (v) =>
    C.gtk_im_context_set_use_preedit @, v

  -- Alas, no introspection support for these signal
  on_commit: (handler, ...) =>
    this = @
    args = pack(...)
    signal.connect 'bool3', @, 'commit', (ctx, str) ->
      handler this, ffi_string(str), unpack(args, args.n)

  on_preedit_start: (handler, ...) =>
    this = @
    args = pack(...)
    signal.connect 'void2', @, 'preedit-start', (ctx) ->
      handler this, unpack(args, args.n)

  on_preedit_changed: (handler, ...) =>
    this = @
    args = pack(...)
    signal.connect 'void2', @, 'preedit-changed', (ctx) ->
      handler this, unpack(args, args.n)

  on_preedit_end: (handler, ...) =>
    this = @
    args = pack(...)
    signal.connect 'void2', @, 'preedit-end', (ctx) ->
      handler this, unpack(args, args.n)

  on_retrieve_surrounding: (handler, ...) =>
    this = @
    args = pack(...)
    signal.connect 'bool2', @, 'retrieve-surrounding', (ctx) ->
      handler this, unpack(args, args.n)

  on_delete_surrounding: (handler, ...) =>
    this = @
    args = pack(...)
    signal.connect 'bool4', @, 'delete-surrounding', (ctx, offset, n_chars) ->
      handler this, tonumber(offset), tonumber(n_chars), unpack(args, args.n)

}
