-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'

C = ffi.C

RGBA = ffi.typeof 'GdkRGBA'

core.define 'GdkRGBA', {
  parse: (spec) =>
    C.gdk_rgba_parse(@, spec) != 0
}, (t, spec) ->
  rgba = RGBA!
  rgba\parse spec if spec
  rgba
