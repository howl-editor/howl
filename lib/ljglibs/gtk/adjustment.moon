-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'

gc_ptr = gobject.gc_ptr

C = ffi.C

jit.off true, true

core.define 'GtkAdjustment < GObject', {
  properties: {
    value: 'gdouble'
    lower: 'gdouble'
    upper: 'gdouble'
    step_increment: 'gdouble'
    page_increment: 'gdouble'
    page_size: 'gdouble'
  }

  new: (value, lower, upper, step_increment, page_increment, page_size) ->
    gc_ptr C.gtk_adjustment_new value, lower,  upper, step_increment, page_increment, page_size

  configure: (value, lower, upper, step_increment, page_increment, page_size) =>
    C.gtk_adjustment_configure @, value, lower,  upper, step_increment, page_increment, page_size

}, (spec, ...) ->
  spec.new ...
