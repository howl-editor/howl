-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'
require 'ljglibs.pango.font_description'
require 'ljglibs.pango.tab_array'
import gc_ptr from require 'ljglibs.gobject'

C, ffi_new, ffi_string, ffi_gc = ffi.C, ffi.new, ffi.string, ffi.gc

PangoRectangle = ffi.typeof 'PangoRectangle'

core.define 'PangoLayoutLine', {
  get_pixel_extents: =>
    logical_rect = PangoRectangle!
    ink_rect = PangoRectangle!
    C.pango_layout_line_get_pixel_extents @, ink_rect, logical_rect
    ink_rect, logical_rect

  index_to_x: (index, trailing) =>
    arr = ffi_new 'int[1]'
    C.pango_layout_line_index_to_x @, index, trailing, arr
    tonumber arr[0]

  x_to_index: (x_pos) =>
    arr = ffi_new 'int[2]'
    outside = C.pango_layout_line_x_to_index @, x_pos, arr, arr + 1
    outside == 1, tonumber(arr[0]), tonumber(arr[1])

  get_height: =>
    res = ffi_new 'int[1]'
    C.pango_layout_line_get_height @, res
    tonumber res[0]
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
      get: => ffi_string @get_text!
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

    indent: {
      get: => tonumber C.pango_layout_get_indent @
      set: (indent) => C.pango_layout_set_indent @, indent
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

    tabs: {
      get: => ffi_gc(C.pango_layout_get_tabs(@), C.pango_tab_array_free)
      set: (tabs) => C.pango_layout_set_tabs @, tabs
    }

    iter: =>
      ffi_gc C.pango_layout_get_iter(@), C.pango_layout_iter_free

    is_wrapped: => C.pango_layout_is_wrapped(@) != 0

    wrap: {
      get: => C.pango_layout_get_wrap(@)
      set: (w) => C.pango_layout_set_wrap(@, w)
    }

    line_count: => tonumber C.pango_layout_get_line_count(@)
  }

  new: (ctx) -> gc_ptr C.pango_layout_new ctx

  get_text: => C.pango_layout_get_text @

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

  -- custom addon
  index_to_pos_for_largest: (s_index, e_index) =>
    max_rect = PangoRectangle!
    rect = PangoRectangle!
    C.pango_layout_index_to_pos @, s_index, max_rect
    for idx = s_index + 1, e_index
      C.pango_layout_index_to_pos @, idx, rect
      if rect.height > max_rect.height
        rect, max_rect = max_rect, rect
    max_rect


}, (t, ...) -> t.new ...
