-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'

C = ffi.C

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
