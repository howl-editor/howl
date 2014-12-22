-- Copyright 2012-2014 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'

C = ffi.C

core.define 'PangoContext', {
  properties: {
    font_description: {
      get: => C.pango_context_get_font_description @
      set: (description) =>
        print "set font description for context"
        C.pango_context_set_font_description @, description
    }
  }
}
