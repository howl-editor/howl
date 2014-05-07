-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.bin'

C = ffi.C

jit.off true

core.define 'GtkEventBox < GtkBin', {
  new: -> C.gtk_event_box_new!
}, (spec) -> spec.new!
