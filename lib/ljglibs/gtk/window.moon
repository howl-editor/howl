-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.bin'

C = ffi.C

core.define 'GtkWindow < GtkBin', {
  new: -> C.gtk_window_new!
}, (spec) -> spec.new!
