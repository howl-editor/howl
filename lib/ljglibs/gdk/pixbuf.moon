-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
glib = require 'ljglibs.glib'
core = require 'ljglibs.core'
require 'ljglibs.cdefs.gdk'

C = ffi.C

core.define 'GdkPixbuf', {
  get_from_window: (window, x, y, width, height) ->
    pixbuf = C.gdk_pixbuf_get_from_window(window, x, y, width, height)
    error 'Failed to get pixbuf' unless pixbuf
    ffi.gc(pixbuf, C.g_object_unref)
    pixbuf

  save: (filename, type) =>
    glib.catch_error(C.gdk_pixbuf_savev, @, filename, type, nil, nil)
}, nil
