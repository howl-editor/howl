-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GtkWidget', {
  override_background_color: (state, color) =>
    C.gtk_widget_override_background_color @, state, color
}
