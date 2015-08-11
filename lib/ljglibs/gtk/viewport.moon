-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.bin'
require 'ljglibs.gtk.adjustment'

gc_ptr = gobject.gc_ptr

C = ffi.C

jit.off true, true

core.define 'GtkViewport < GtkBin', {
  properties: {
  }

  new: (hadjustment, vadjustment) ->
    gc_ptr C.gtk_viewport_new hadjustment, vadjustment

}, (spec, ...) ->
  spec.new ...
