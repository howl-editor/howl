-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
glib = require 'ljglibs.glib'
core = require 'ljglibs.core'
require 'ljglibs.gtk.bin'

C = ffi.C
catch_error = glib.catch_error

core.define 'GtkWindow < GtkBin', {
  constants: {
    prefix: 'GTK_WINDOW_'
    'TOPLEVEL',
    'POPUP'
  }

  new: -> C.gtk_window_new!

  set_default_icon_from_file: (filename) ->
    catch_error(C.gtk_window_set_default_icon_from_file, filename) != 0

}, (spec) -> spec.new!
