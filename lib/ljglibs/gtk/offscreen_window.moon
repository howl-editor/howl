-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
core = require 'ljglibs.core'
require 'ljglibs.gtk.window'

C = ffi.C

core.define 'GtkOffscreenWindow < GtkWindow', {
  new: -> C.gtk_offscreen_window_new!
}, (spec) -> spec.new!
