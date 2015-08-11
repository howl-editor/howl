-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

gc_ptr = gobject.gc_ptr
C = ffi.C

core.define 'GtkDrawingArea < GtkWidget', {
  new: -> gc_ptr C.gtk_drawing_area_new!
}, (spec) -> spec.new!
