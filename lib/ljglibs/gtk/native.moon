-- Copyright 2023 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GtkNative', {

  get_surface: =>
    C.gtk_native_get_surface @

  get_renderer: =>
    require 'ljglibs.gsk.renderer'
    C.gtk_native_get_renderer @

  -- the offset of the native's widget within its surface, such as for a
  -- client side shadow
  get_surface_transform: =>
    ret = ffi.new 'double[2]'
    C.gtk_native_get_surface_transform @, ret, ret + 1
    ret[0], ret[1]

  get_surface_scale: =>
    C.gdk_surface_get_scale @get_surface!

  -- the position of a popup's surface relative to its parent's surface
  get_popup_position: =>
    popup = ffi.cast 'GdkPopup *', @get_surface!
    C.gdk_popup_get_position_x(popup), C.gdk_popup_get_position_y(popup)

}
