-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

gc_ptr = gobject.gc_ptr
C = ffi.C

jit.off true, true

core.define 'GtkSpinner < GtkWidget', {
  properties: {
    active: 'gboolean'
  }

  new: -> gc_ptr C.gtk_spinner_new!
  start: => C.gtk_spinner_start @
  stop: => C.gtk_spinner_stop @

}, (spec) -> spec.new!
