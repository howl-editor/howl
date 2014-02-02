-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.widget'

C, ffi_cast = ffi.C, ffi.cast

widget_t = ffi.typeof 'GtkWidget *'

core.define 'GtkContainer < GtkWidget', {
  add: (widget) => C.gtk_container_add @, ffi_cast(widget_t, widget)
  remove: (widget) => C.gtk_container_remove @, ffi_cast(widget_t, widget)
}
