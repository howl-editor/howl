-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)
core = require 'ljglibs.core'

require 'ljglibs.cdefs.pango'
require 'ljglibs.pango.layout'
ffi = require 'ffi'
import gc_ptr from require 'ljglibs.gobject'
C, ffi_string, ffi_gc, ffi_new = ffi.C, ffi.string, ffi.gc, ffi.new

{
  create_context: (cr) ->
    gc_ptr C.pango_cairo_create_context(cr)

  create_layout: (cr) ->
    gc_ptr C.pango_cairo_create_layout(cr)

  show_layout: (cr, layout) ->
    C.pango_cairo_show_layout cr, layout
}
