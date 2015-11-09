-- Copyright 2012-2014 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
core = require 'ljglibs.core'
require 'ljglibs.cdefs.gtk'
require 'ljglibs.gobject.object'
gobject = require 'ljglibs.gobject'

ref_ptr = gobject.ref_ptr
C = ffi.C

jit.off true, true

core.define 'GtkSettings < GObject', {
  properties: {
    gtk_cursor_blink: 'gboolean'
    gtk_cursor_blink_time: 'gint'
    gtk_cursor_blink_timeout: 'gint'
    gtk_font_name: 'gchar*'
    gtk_im_module: 'gchar*'
  }

  get_default: ->
    ref_ptr C.gtk_settings_get_default!

  get_for_screen: (screen) ->
    ref_ptr C.gtk_settings_get_for_screen screen
}
