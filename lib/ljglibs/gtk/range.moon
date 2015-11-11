-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.adjustment'

jit.off true, true

core.define 'GtkRange < GtkWidget', {
  properties: {
    adjustment: 'GtkAdjustment *'
    fill_level: 'gdouble'
    inverted: 'gboolean'
    restrict_to_fill_level: 'gboolean'
    round_digits: 'gint'
    show_fill_level: 'gboolean'
  }

}, -> error 2, 'GtkRange is an uninstantiable base class'
