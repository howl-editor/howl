-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GtkWidget', {
  realize: => C.gtk_widget_realize @
  show: => C.gtk_widget_show @
  hide: => C.gtk_widget_hide @

  override_background_color: (state, color) =>
    C.gtk_widget_override_background_color @, state, color
}
