-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'
require 'ljglibs.pango.font_description'
import gc_ptr from require 'ljglibs.gobject'

C, ffi_new, ffi_string, ffi_gc = ffi.C, ffi.new, ffi.string, ffi.gc

PangoRectangle = ffi.typeof 'PangoRectangle'

core.define 'PangoLayoutLine', {
  get_pixel_extents: =>
    logical_rect = PangoRectangle!
    ink_rect = PangoRectangle!
    C.pango_layout_line_get_pixel_extents @, ink_rect, logical_rect
    ink_rect, logical_rect
}

core.define 'PangoLayoutIter', {
  properties: {
    at_last_line: => C.pango_layout_iter_at_last_line(@) != 0
    baseline: => tonumber C.pango_layout_iter_get_baseline @

    line: =>
      line = C.pango_layout_iter_get_line @
      return nil if line == nil
      ffi_gc(C.pango_layout_line_ref(line), C.pango_layout_line_unref)

    line_readonly: =>
      line = C.pango_layout_iter_get_line_readonly @
      return nil if line == nil
      ffi_gc(C.pango_layout_line_ref(line), C.pango_layout_line_unref)

    yrange: =>
      arr = ffi_new 'int[2]'
      C.pango_layout_iter_get_line_yrange @, arr, arr + 1
      y0: tonumber(arr[0]), y1: tonumber(arr[1])
  }

  next_line: => C.pango_layout_iter_next_line(@) != 0
}

core.define 'PangoLayout', {

  properties: {
    text: {
      get: => ffi_string C.pango_layout_get_text @
      set: (text) => @set_text text
    }

    width: {
      get: => tonumber C.pango_layout_get_width @
      set: (width) => C.pango_layout_set_width @, width
    }

    height: {
      get: => tonumber C.pango_layout_get_height @
      set: (height) => C.pango_layout_set_height @, height
    }

    spacing: {
      get: => tonumber C.pango_layout_get_spacing @
      set: (spacing) => C.pango_layout_set_spacing @, spacing
    }

    alignment: {
      get: => tonumber C.pango_layout_get_alignment @
      set: (alignment) => C.pango_layout_set_alignment @, alignment
    }

    attributes: {
      get: => C.pango_layout_get_attributes @
      set: (attributes) => C.pango_layout_set_attributes @, attributes
    }

    baseline: => tonumber C.pango_layout_get_baseline @

    font_description: {
      get: =>
        desc = C.pango_layout_get_font_description @
        desc != nil and desc or nil

      set: (desc) => C.pango_layout_set_font_description @, desc
    }

    iter: =>
      ffi_gc C.pango_layout_get_iter(@), C.pango_layout_iter_free
  }

  new: (ctx) -> gc_ptr C.pango_layout_new ctx

  set_text: (text, length = -1) =>
    C.pango_layout_set_text @, text, length

  get_pixel_size: =>
    arr = ffi_new 'int[2]'
    C.pango_layout_get_pixel_size @, arr, arr + 1
    tonumber(arr[0]), tonumber(arr[1])

  index_to_pos: (index) =>
    rect = PangoRectangle!
    C.pango_layout_index_to_pos @, index, rect
    rect

  xy_to_index: (x, y) =>
    arr = ffi_new 'int[2]'
    inside = C.pango_layout_xy_to_index(@, x, y, arr, arr + 1) != 0
    inside, tonumber(arr[0]), tonumber(arr[1])

  index_to_line_x: (index, trailing) =>
    arr = ffi_new 'int[2]'
    C.pango_layout_index_to_line_x @, index, trailing, arr, arr + 1
    tonumber(arr[0]), tonumber(arr[1])

  move_cursor_visually: (strong, old_index, old_trailing, direction) =>
    arr = ffi_new 'int[2]'
    C.pango_layout_move_cursor_visually @, strong, old_index, old_trailing, direction, arr, arr + 1
    tonumber(arr[0]), tonumber(arr[1])

  get_line: (nr) =>
    line = C.pango_layout_get_line @, nr
    return nil if line == nil
    ffi_gc(C.pango_layout_line_ref(line), C.pango_layout_line_unref)

  get_line_readonly: (nr) =>
    line = C.pango_layout_get_line_readonly @, nr
    return nil if line == nil
    ffi_gc(C.pango_layout_line_ref(line), C.pango_layout_line_unref)

}, (t, ...) -> t.new ...
