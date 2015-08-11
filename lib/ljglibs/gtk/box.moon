-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'

require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.container'

gc_ptr = gobject.gc_ptr
C, ffi_cast = ffi.C, ffi.cast

widget_t = ffi.typeof 'GtkWidget *'
to_w = (o) -> ffi_cast widget_t, o

jit.off true, true

core.define 'GtkBox < GtkContainer', {
  properties: {
    homogeneous: 'gboolean'
    spacing: 'gint'
  }

  child_properties: {
    expand: 'gboolean'
    fill: 'gboolean'
    pack_type: 'GtkPackType'
    padding: 'guint'
    position: 'gint'
  }

  new: (orientation = C.GTK_ORIENTATION_HORIZONTAL, spacing = 0) ->
    gc_ptr C.gtk_box_new orientation, spacing

  pack_start: (child, expand, fill, padding) =>
    C.gtk_box_pack_start @, to_w(child), expand, fill, padding

  pack_end: (child, expand, fill, padding) =>
    C.gtk_box_pack_end @, to_w(child), expand, fill, padding

}, (spec, ...) -> spec.new ...
