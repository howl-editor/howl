-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'
callbacks = require 'ljglibs.callbacks'

gc_ptr = gobject.gc_ptr
C = ffi.C
ffi_cast = ffi.cast
int_t = ffi.typeof 'int'
cairo_t = ffi.typeof 'cairo_t *'

jit.off true, true

core.define 'GtkDrawingArea < GtkWidget', {
  new: -> gc_ptr C.gtk_drawing_area_new!

  unset_draw_func: (handler) =>
    -- C.gtk_drawing_area_set_draw_func @, nil, nil, nil
    callbacks.unregister handler

  set_draw_func: (f) =>
    handler = (drawing_area, cr, width, height) ->
      cr = ffi_cast cairo_t, cr
      width = tonumber(ffi_cast int_t, width)
      height = tonumber(ffi_cast int_t, height)
      f cr, width, height

    cb_handle = callbacks.register handler, 'draw-function'
    cb_cast = ffi.cast('GtkDrawingAreaDrawFunc', callbacks.void5)
    cb_data = callbacks.cast_arg(cb_handle.id)
    C.gtk_drawing_area_set_draw_func @, cb_cast, cb_data, nil
    cb_handle


}, (spec) -> spec.new!
