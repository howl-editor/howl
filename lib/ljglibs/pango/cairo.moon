-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
require 'ljglibs.core'

require 'ljglibs.cdefs.pango'
require 'ljglibs.pango.layout'
ffi = require 'ffi'
import gc_ptr from require 'ljglibs.gobject'
C = ffi.C

{
  create_context: (cr) ->
    gc_ptr C.pango_cairo_create_context(cr)

  create_layout: (cr) ->
    gc_ptr C.pango_cairo_create_layout(cr)

  show_layout: (cr, layout) ->
    C.pango_cairo_show_layout cr, layout
}
