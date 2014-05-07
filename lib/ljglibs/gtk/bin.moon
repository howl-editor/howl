-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'

require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.container'

C = ffi.C
ref_ptr = gobject.ref_ptr

jit.off true

core.define 'GtkBin < GtkContainer', {
  properties: {
    child: => @get_child!
  }

  get_child: => ref_ptr C.gtk_bin_get_child @
}
