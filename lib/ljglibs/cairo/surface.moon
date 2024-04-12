-- Copyright 2014-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.cairo'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

C, gc = ffi.C, ffi.gc

release = (o) ->
  gobject.register_deallocation 'CairoSurface'
  C.cairo_surface_destroy(o)

surface_gc_ptr = (o) ->
  gobject.register_allocation 'CairoSurface'
  gc(o, release)

core.define 'cairo_surface_t', {

  create_similar: (other, content, width, height) ->
    surface_gc_ptr C.cairo_surface_create_similar other, content, width, height

  write_to_png: (filename) =>
    C.cairo_surface_write_to_png @, filename

  status: =>
    C.cairo_surface_status @

  destroy: =>
    gc(@, nil)
    C.cairo_surface_destroy @

}
