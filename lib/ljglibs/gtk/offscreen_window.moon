-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.window'

C = ffi.C
ref_ptr = gobject.ref_ptr

jit.off true, true

core.define 'GtkOffscreenWindow < GtkWindow', {
  new: -> ref_ptr C.gtk_offscreen_window_new!
}, (spec) -> spec.new!
