-- Copyright 2012-2014 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'
Pango = require 'ljglibs.pango'

C, ffi_gc = ffi.C, ffi.gc

core.define 'PangoTabArray', {
  properties: {
    positions_in_pixels: => C.pango_tab_array_get_positions_in_pixels(@) != 0
    size: => tonumber C.pango_tab_array_get_size(@)

    tabs: =>
      setmetatable {}, {
        __index: (_, k) ->
          return nil if k > @size
          @\get_tab(k - 1).location

        __newindex: (_, k, v) ->
          @\set_tab k - 1, Pango.TAB_LEFT, v
      }
  }

  set_tab: (index, alignment, location) =>
    error "Invalid tab stop #{index}", 2 if index >= @size
    C.pango_tab_array_set_tab(@, index, alignment, location)

  get_tab: (index) =>
    error "Invalid tab stop #{index}", 2 if index >= @size
    t_align = ffi.new('PangoTabAlign[1]')
    location = ffi.new('gint[1]')
    C.pango_tab_array_get_tab(@, index, t_align, location)
    alignment: tonumber(t_align[0]), location: tonumber location[0]

}, (t, size, size_in_pixels, initial = nil) ->
  tab_array = ffi_gc(C.pango_tab_array_new(size, size_in_pixels), C.pango_tab_array_free)

  if initial
    if type(initial) == 'number'
      location = initial
      for i = 0, size - 1
        tab_array\set_tab i, Pango.TAB_LEFT, location
        location += initial

  tab_array
