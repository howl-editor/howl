-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.bin'

C = ffi.C

jit.off true, true

core.define 'GtkEventBox < GtkBin', {
  new: -> C.gtk_event_box_new!
}, (spec) -> spec.new!
