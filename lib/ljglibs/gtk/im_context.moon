-- Copyright 2015-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
core = require 'ljglibs.core'
{:g_string} = require 'ljglibs.glib'
require 'ljglibs.cdefs.gtk'
require 'ljglibs.gobject.object'

C, ffi_new, ffi_gc, ffi_cast = ffi.C, ffi.string, ffi.new, ffi.gc, ffi.cast

jit.off true, true

widget_t = ffi.typeof 'GtkWidget *'

core.define 'GtkIMContext < GObject', {
  properties: {
    client_widget:
      set: (widget) =>
        print "widget_t: #{widget_t}"
        print "type: #{ffi.typeof 'GtkWidget *'}"
        print "widget: #{widget}"
        @set_client_widget ffi_cast(widget_t, widget)

    use_preedit:
      set: (v) => @set_use_preedit v
  }

  set_client_widget: (widget) =>
    C.gtk_im_context_set_client_widget @, widget

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
}
