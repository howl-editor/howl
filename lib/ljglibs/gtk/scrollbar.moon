-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.range'

gc_ptr = gobject.gc_ptr

C = ffi.C

jit.off true, true

core.define 'GtkScrollbar < GtkRange', {
  properties: {
  }

  new: (orientation, adjustment = nil) ->
    gc_ptr C.gtk_scrollbar_new orientation, adjustment

}, (spec, ...) ->
  spec.new ...
