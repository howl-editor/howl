-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
require 'ljglibs.gobject.object'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

gc_ptr = gobject.gc_ptr
C, ffi_cast = ffi.C, ffi.cast
widget_t = ffi.typeof 'GtkWidget *'

rect = (x, y, width, height) -> ffi.new 'graphene_rect_t', { { x, y }, { width, height } }

core.define 'GtkSnapshot < GObject', {
  save: => C.gtk_snapshot_save @
  restore: => C.gtk_snapshot_restore @

  translate: (x, y) =>
    C.gtk_snapshot_translate @, ffi.new('graphene_point_t', x, y)

  scale: (x, y) => C.gtk_snapshot_scale @, x, y

  append_color: (rgba, x, y, width, height) =>
    C.gtk_snapshot_append_color @, rgba, rect(x, y, width, height)

  -- appends widget's current rendering, at the size given
  append_widget: (widget, width, height) =>
    paintable = C.gtk_widget_paintable_new ffi_cast(widget_t, widget)
    C.gdk_paintable_snapshot paintable, @, width, height
    C.g_object_unref paintable

  -- returns the render node for what was appended, after which nothing more
  -- can be appended
  to_node: =>
    node = C.gtk_snapshot_to_node @
    node != nil and ffi.gc(node, C.gsk_render_node_unref) or nil

}, (spec) -> gc_ptr C.gtk_snapshot_new!
