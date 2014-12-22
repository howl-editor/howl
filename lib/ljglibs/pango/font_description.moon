-- Copyright 2012-2014 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'

C, ffi_string, ffi_gc = ffi.C, ffi.string, ffi.gc

core.define 'PangoFontDescription', {
  properties: {
    family: {
      get: => ffi_string(C.pango_font_description_get_family(@))
      set: (family) =>
        C.pango_font_description_set_family @, ffi.cast('const char *', family)
    }

    size: {
      get: => C.pango_font_description_get_size @
      set: (size) => C.pango_font_description_set_size @, size
    }

    absolute_size: {
      set: (size) => C.pango_font_description_set_absolute_size @, size
    }

    size_is_absolute: {
      get: => C.pango_font_description_get_size_is_absolute(@) != 0
    }
  }

  from_string: (s) ->
    ffi_gc(C.pango_font_description_from_string(s), C.pango_font_description_free)

  meta: {
    __tostring: => ffi.string C.pango_font_description_to_string @
  }
}, (t, initial = {}) ->
  desc = ffi_gc(C.pango_font_description_new!, C.pango_font_description_free)
  desc[k] = v for k, v in pairs initial
  desc
