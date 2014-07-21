-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.bin'
require 'ljglibs.gtk.adjustment'

C = ffi.C
{:ref_ptr, :gc_ptr} = gobject

jit.off true, true

core.define 'GtkScrolledWindow < GtkBin', {

  properties: {
    hadjustment: 'GtkAdjustment *'
    vadjustment: 'GtkAdjustment *'
  }

  new: (hadjustment = nil, vadjustment = nil) -> gc_ptr C.gtk_scrolled_window_new hadjustment, vadjustment

}, (spec, hadjustment, vadjustment) -> spec.new hadjustment, vadjustment
