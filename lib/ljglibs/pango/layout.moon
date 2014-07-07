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

    alignment: {
      get: => C.pango_layout_get_alignment @
      set: (alignment) => C.pango_layout_set_alignment @, alignment
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

  move_cursor_visually: (strong, old_index, old_trailing, direction) =>
    arr = ffi_new 'int[2]'
    C.pango_layout_move_cursor_visually @, strong, old_index, old_trailing, direction, arr, arr + 1
    tonumber(arr[0]), tonumber(arr[1])

}, (t, ...) -> t.new ...
