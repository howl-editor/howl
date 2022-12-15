-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

gc_ptr, ref_ptr = gobject.gc_ptr, gobject.ref_ptr
C, ffi_cast = ffi.C, ffi.cast
widget_t = ffi.typeof 'GtkWidget *'
int_ptr_t = ffi.typeof 'int[1]'
to_w = (o) -> ffi_cast widget_t, o

jit.off true, true

core.define 'GtkGrid < GtkWidget', {
  properties: {
    column_homogeneous: 'gboolean'
    row_homogeneous: 'gboolean'
    column_spacing: 'gint'
    row_spacing: 'gint'
    baseline_row: 'gint'
  }

  new: -> gc_ptr C.gtk_grid_new!

  attach: (child, col, row, width, height) =>
    C.gtk_grid_attach @, to_w(child), col, row, width, height

  attach_next_to: (child, sibling, side, width, height) =>
    C.gtk_grid_attach_next_to @, to_w(child), to_w(sibling), side, width, height

  get_child_at: (left, top) => ref_ptr C.gtk_grid_get_child_at @, left, top
  insert_row: (position) => C.gtk_grid_insert_row @, position
  insert_column: (position) => C.gtk_grid_insert_column @, position
  remove_row: (position) => C.gtk_grid_remove_row @, position
  remove_column: (position) => C.gtk_grid_remove_column @, position
  insert_next_to: (sibling, side) => C.gtk_grid_insert_next_to @, to_w(sibling), side
  remove: (child) => C.gtk_grid_remove @, to_w(child)
  query_child: (child) =>
    col = int_ptr_t!
    row = int_ptr_t!
    w = int_ptr_t!
    h = int_ptr_t!
    C.gtk_grid_query_child @, to_w(child), col, row, w, h
    {
      column: tonumber(col[0]),
      row: tonumber(row[0])
      width: tonumber(w[0])
      height: tonumber(h[0])
    }


}, (spec, ...) -> spec.new ...
