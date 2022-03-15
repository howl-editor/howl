-- Copyright 2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'

C = ffi.C

jit.off true, true

core.define 'GtkCssSection', {
  properties: {
    -- added properties
    start_location: => C.gtk_css_section_get_start_location @
    end_location: => C.gtk_css_section_get_end_location @
  }

  to_string: =>
    ptr = C.gtk_css_section_to_string(@)
    s = ffi.string ptr
    C.g_free ptr
    s
}
