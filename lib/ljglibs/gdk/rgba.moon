-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
{:g_string} = require 'ljglibs.glib'

C = ffi.C

RGBA = ffi.typeof 'GdkRGBA'

core.define 'GdkRGBA', {
  parse: (spec) =>
    C.gdk_rgba_parse(@, spec) != 0

  meta: {
    __tostring: => g_string C.gdk_rgba_to_string(@)
  }
}, (t, spec) ->
  rgba = RGBA!
  rgba\parse spec if spec
  rgba
