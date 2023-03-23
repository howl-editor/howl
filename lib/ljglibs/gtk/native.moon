-- Copyright 2023 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GtkNative', {

  get_surface: =>
    C.gtk_native_get_surface @

}
