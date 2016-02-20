-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'

C = ffi.C

{
  set_source_pixbuf: (cr, pixbuf, x, y) ->
    C.gdk_cairo_set_source_pixbuf cr, pixbuf, x, y
}

