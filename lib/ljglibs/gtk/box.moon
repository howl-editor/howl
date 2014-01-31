-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
require 'ljglibs.gtk.container'

C = ffi.C

core.define 'GtkBox < GtkContainer', {
  new: (orientation, spacing) -> C.gtk_box_new orientation, spacing
}, (spec, ...) -> spec.new ...
