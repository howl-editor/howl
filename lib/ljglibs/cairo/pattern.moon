-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.cairo'
core = require 'ljglibs.core'

C, gc = ffi.C, ffi.gc

gc_ptr = (o) ->
  gc(o, C.cairo_pattern_destroy)

core.define 'cairo_pattern_t', {

  properties: {
    extend: {
      get: => C.cairo_pattern_get_extend @
      set: (extend) => C.cairo_pattern_set_extend @, extend
    }
  }

  create_linear: (x0, y0, x1, y1) ->
    gc_ptr C.cairo_pattern_create_linear x0, y0, x1, y1

  add_color_stop_rgba: (offset, red, green, blue, alpha) =>
    C.cairo_pattern_add_color_stop_rgba @, offset, red, green, blue, alpha
}
