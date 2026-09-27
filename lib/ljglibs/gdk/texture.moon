-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
require 'ljglibs.gobject.object'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GdkTexture < GObject', {
  properties: {
    width: 'gint'
    height: 'gint'
  }

  save_to_png: (filename) =>
    unless C.gdk_texture_save_to_png(@, filename) != 0
      error "Failed to save texture to '#{filename}'"
}
