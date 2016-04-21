-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

C = ffi.C
ref_ptr = gobject.ref_ptr

core.define 'GdkDisplay < GObject', {
  properties: {
    has_pending: => C.gdk_display_has_pending(@) != 0
  }

  get_default: -> ref_ptr C.gdk_display_get_default!
  sync: => C.gdk_display_sync @
}
