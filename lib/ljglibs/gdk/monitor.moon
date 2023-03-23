-- Copyright 2023 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GdkMonitor < GObject', {
  get_geometry: =>
    rect = ffi.new('GdkRectangle[1]')
    C.gdk_monitor_get_geometry @, rect
    {
      x: rect[0].x,
      y: rect[0].y,
      width: rect[0].width,
      height: rect[0].height,
      }
}
