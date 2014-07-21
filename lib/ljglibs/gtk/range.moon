-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.adjustment'

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
