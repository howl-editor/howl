-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.widget'

core.define 'GtkMisc < GtkWidget', {
  properties: {
    xalign: 'gfloat'
    yalign: 'gfloat'
    xpad: 'gint'
    ypad: 'gint'
  }
}
