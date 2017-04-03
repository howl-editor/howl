-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
C = ffi.C

core.define 'GtkSelectionData', {
  set_text: (text) =>
    C.gtk_selection_data_set_text @, text, #text
}
