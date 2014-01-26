-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GdkScreen', {
  get_default: -> C.gdk_screen_get_default!
}
