-- Copyright 2014-2021 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'

require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

gc_ptr = gobject.gc_ptr
C, ffi_cast = ffi.C, ffi.cast

widget_t = ffi.typeof 'GtkWidget *'
to_w = (o) -> ffi_cast widget_t, o

jit.off true, true

core.define 'GtkBox < GtkWidget', {
  properties: {
    homogeneous: 'gboolean'
    spacing: 'gint'
  }

  new: (orientation = C.GTK_ORIENTATION_HORIZONTAL, spacing = 0) ->
    gc_ptr C.gtk_box_new orientation, spacing

  add: (child) =>
    C.gtk_box_append @, to_w(child)

  append: (child) =>
    C.gtk_box_append @, to_w(child)

  prepend: (child) =>
    C.gtk_box_prepend @, to_w(child)

  remove: (child) =>
    C.gtk_box_remove @, to_w(child)

  insert_child_after: (child, sibling) =>
    C.gtk_box_insert_child_after @, to_w(child), to_w(sibling)

}, (spec, ...) -> spec.new ...
