-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'
import gc_ptr from require 'ljglibs.gobject'

C, ffi_new = ffi.C, ffi.new

PangoRectangle = ffi.typeof 'PangoRectangle'

core.define 'PangoLayout', {

  properties: {
    text: {
      set: (text) => @set_text text
    }

    width: {
      get: => C.pango_layout_get_width @
      set: (width) => C.pango_layout_set_width @, width
    }

    height: {
      get: => C.pango_layout_get_height @
      set: (height) => C.pango_layout_set_height @, height
    }

    spacing: {
      get: => C.pango_layout_get_spacing @
      set: (spacing) => C.pango_layout_set_spacing @, spacing
    }

    alignment: {
      get: => C.pango_layout_get_alignment @
      set: (alignment) => C.pango_layout_set_alignment @, alignment
    }

    attributes: {
      get: => C.pango_layout_get_attributes @
      set: (attributes) => C.pango_layout_set_attributes @, attributes
    }
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

  move_cursor_visually: (strong, old_index, old_trailing, direction) =>
    arr = ffi_new 'int[2]'
    C.pango_layout_move_cursor_visually @, strong, old_index, old_trailing, direction, arr, arr + 1
    tonumber(arr[0]), tonumber(arr[1])

}, (t, ...) -> t.new ...
