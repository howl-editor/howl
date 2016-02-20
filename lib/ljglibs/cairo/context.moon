-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.cairo'
core = require 'ljglibs.core'
import gc_ptr from require 'ljglibs.gobject'
require 'ljglibs.cairo.pattern'

C, gc = ffi.C, ffi.gc

cairo_gc_ptr = (o) ->
  gc(o, C.cairo_destroy)

core.define 'cairo_t', {

  properties: {
    line_width: {
      get: => tonumber C.cairo_get_line_width @
      set: (width) => C.cairo_set_line_width @, width
    }

    clip_extents: =>
      a = ffi.new 'double[4]'
      C.cairo_clip_extents @, a, a + 1, a + 2, a + 3
      { x1: tonumber(a[0]), y1: tonumber(a[1]), x2: tonumber(a[2]), y2: tonumber(a[3]) }

    fill_extents: =>
      a = ffi.new 'double[4]'
      C.cairo_fill_extents @, a, a + 1, a + 2, a + 3
      { x1: tonumber(a[0]), y1: tonumber(a[1]), x2: tonumber(a[2]), y2: tonumber(a[3]) }

    status: => C.cairo_status @

    operator: {
      get: => C.cairo_get_operator @
      set: (operator) => C.cairo_set_operator @, operator
    }

    line_join: {
      get: => C.cairo_get_line_join @
      set: (lj) => C.cairo_set_line_join @, lj
    }

    line_cap: {
      get: => C.cairo_get_line_cap @
      set: (lc) => C.cairo_set_line_cap @, lc
    }

    dash: {
      get: => @get_dash!
      set: (a) => @set_dash a
    }

    dash_count: =>
      tonumber C.cairo_get_dash_count(@)

    target: =>
      C.cairo_get_target @

    source: {
      get: => @get_source!
      set: (v) => @set_source v
    }

    has_current_point: => C.cairo_has_current_point(@) != 0
  }

  create: (surface) -> cairo_gc_ptr C.cairo_create surface
  save: => C.cairo_save @
  restore: => C.cairo_restore @

  set_source: (source) => C.cairo_set_source @, source
  set_source_rgb: (r, g, b) => C.cairo_set_source_rgb @, r, g, b
  set_source_rgba: (r, g, b, a) => C.cairo_set_source_rgba @, r, g, b, a
  set_source_surface: (surface, x, y) => C.cairo_set_source_surface @, surface, x, y

  get_source: =>
    src = C.cairo_get_source(@)
    gc(C.cairo_pattern_reference(src), C.cairo_pattern_destroy)

  set_dash: (dashes, offset = 1) =>
    count = (#dashes - offset) + 1
    a = ffi.new 'double[?]', count
    for i = 1, count
      a[i - 1] = dashes[offset + i - 1]

    C.cairo_set_dash @, a, count, 0

  get_dash: =>
    count = @dash_count
    return {} if count < 1
    a = ffi.new 'double[?]', count
    C.cairo_get_dash @, a, nil
    dashes = {}
    for i = 1, count
      dashes[i] = a[i - 1]

  stroke: => C.cairo_stroke @
  stroke_preserve: => C.cairo_stroke_preserve @
  fill: => C.cairo_fill @
  fill_preserve: => C.cairo_fill_preserve @
  line_to: (x, y) => C.cairo_line_to @, x, y
  rel_line_to: (dx, dy) => C.cairo_rel_line_to @, dx, dy
  move_to: (x, y) => C.cairo_move_to @, x, y
  rel_move_to: (x, y) => C.cairo_rel_move_to @, x, y

  in_clip: (x, y) => C.cairo_in_clip(@, x, y) != 0
  clip: => C.cairo_clip @
  clip_preserve: => C.cairo_clip_preserve @

  push_group: => C.cairo_push_group @
  pop_group: => C.cairo_pop_group @

  -- Path operations
  rectangle: (x, y, width, height) => C.cairo_rectangle @, x, y, width, height
  arc: (xc, yc, radius, angle1, angle2) => C.cairo_arc @, xc, yc, radius, angle1, angle2
  close_path: => C.cairo_close_path @
  new_path: => C.cairo_new_path @

  -- Transformations
  translate: (tx, ty) => C.cairo_translate @, tx, ty

}, (t, ...) -> t.create ...
