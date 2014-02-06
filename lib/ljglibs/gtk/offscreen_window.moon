-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.window'

C = ffi.C
gc_ptr = gobject.gc_ptr

core.define 'GtkOffscreenWindow < GtkWindow', {
  -- todo: gc_ptr below
  new: -> C.gtk_offscreen_window_new!
}, (spec) -> spec.new!
