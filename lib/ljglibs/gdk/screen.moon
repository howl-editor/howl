-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

ref_ptr = gobject.ref_ptr

C = ffi.C

core.define 'GdkScreen', {
  properties: {
    font_options: 'gpointer'
    resolution: 'gdouble'

    -- Added properties
    number: => C.gdk_screen_get_number @
    width: => C.gdk_screen_get_width @
    height: => C.gdk_screen_get_height @
    width_mm: => C.gdk_screen_get_width_mm @
    height_mm: => C.gdk_screen_get_height_mm @
  }

  get_default: -> ref_ptr C.gdk_screen_get_default!
}
