-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'

C = ffi.C

core.define 'GtkWidget', {
  constants: {
    -- GtkStateFlags
    'GTK_STATE_FLAG_NORMAL',
    'GTK_STATE_FLAG_ACTIVE',
    'GTK_STATE_FLAG_PRELIGHT',
    'GTK_STATE_FLAG_SELECTED',
    'GTK_STATE_FLAG_INSENSITIVE',
    'GTK_STATE_FLAG_INCONSISTENT',
    'GTK_STATE_FLAG_FOCUSED',
  }

  override_background_color: (state, color) =>
    C.gtk_widget_override_background_color @, state, color
}
