-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'

C, ffi_new, ffi_gc = ffi.C, ffi.new, ffi.gc

pc_t = ffi.typeof 'PangoColor'

core.define 'PangoColor', {
  new: (r, g, b)->
    color = pc_t!
    if type(r) == 'string'
      color\parse r
    else
      with color
        .red = r
        .green = g
        .blue = b

    color

  parse: (spec) =>
    if C.pango_color_parse(@, spec) == 0
      error "Illegal color '#{spec}'", 2

  meta: {
    __tostring: => ffi.string C.pango_color_to_string(@)
  }

}, (t, ...) -> t.new ...
