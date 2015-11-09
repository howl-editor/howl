-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
core = require 'ljglibs.core'
require 'ljglibs.gtk.im_context'
gobject = require 'ljglibs.gobject'

ref_ptr = gobject.ref_ptr
C = ffi.C

jit.off true, true

core.define 'GtkIMContextSimple < GtkIMContext', {
  new: ->
    ref_ptr C.gtk_im_context_simple_new!
}, => @new!
