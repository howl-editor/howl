-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

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
    print 'new'
    gc_ptr C.gtk_viewport_new hadjustment, vadjustment

}, (spec, ...) ->
  spec.new ...
