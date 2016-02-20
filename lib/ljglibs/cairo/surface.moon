-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.cairo'
core = require 'ljglibs.core'

C, gc = ffi.C, ffi.gc

surface_gc_ptr = (o) ->
  gc(o, C.cairo_surface_destroy)

core.define 'cairo_surface_t', {

  properties: {
  }

  create_similar: (other, content, width, height) ->
    surface_gc_ptr C.cairo_surface_create_similar other, content, width, height

  write_to_png: (filename) =>
    C.cairo_surface_write_to_png @, filename

  destroy: =>
    gc(@, nil)
    C.cairo_surface_destroy @

}
