-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gdk.display'

ref_ptr = gobject.ref_ptr

C = ffi.C

core.define 'GdkScreen < GObject', {
  properties: {
    font_options: 'gpointer'
    resolution: 'gdouble'

    -- Added properties
    number: => C.gdk_screen_get_number @
    width: => C.gdk_screen_get_width @
    height: => C.gdk_screen_get_height @
    width_mm: => C.gdk_screen_get_width_mm @
    height_mm: => C.gdk_screen_get_height_mm @
    rgba_visual: => C.gdk_screen_get_rgba_visual @
    is_composited: => C.gdk_screen_is_composited(@) != 0
    root_window: => ref_ptr C.gdk_screen_get_root_window @
    display: => ref_ptr C.gdk_screen_get_display @
  }

  get_default: -> ref_ptr C.gdk_screen_get_default!
}
