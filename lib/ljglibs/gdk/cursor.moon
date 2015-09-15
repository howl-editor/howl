-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

ref_ptr = gobject.ref_ptr

C = ffi.C

core.define 'GdkCursor', {
  properties: {
    cursor_type: 'GdkCursorType'
  }

  new: (cursor_type) -> ref_ptr C.gdk_cursor_new(cursor_type)
}, (spec, ...) -> spec.new ...

