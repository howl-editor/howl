-- Copyright 2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
{cast: ffi_cast} = ffi
jit = require 'jit'

require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

gc_ptr = gobject.gc_ptr
C = ffi.C
widget_t = ffi.typeof 'GtkWidget *'
to_w = (o) -> ffi_cast widget_t, o

jit.off true, true

core.define 'GtkListBox < GtkWidget', {
  properties: {
  }

  new: -> gc_ptr C.gtk_list_box_new!
  append: (widget) => C.gtk_list_box_append @, to_w(widget)
  remove: (widget) => C.gtk_list_box_remove @, to_w(widget)

}, (spec, ...) -> spec.new ...
