-- Copyright 2014-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
jit = require 'jit'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.widget'

C = ffi.C
{:gc_ptr} = gobject

jit.off true, true

core.define 'GtkScrolledWindow < GtkWidget', {

  properties: {
    hadjustment: 'const GtkAdjustment *'
    vadjustment: 'const GtkAdjustment *'
    child: 'const GtkWidget *'
  }

  new: (hadjustment = nil, vadjustment = nil) ->
    gc_ptr C.gtk_scrolled_window_new hadjustment, vadjustment

}, (spec, hadjustment, vadjustment) -> spec.new hadjustment, vadjustment
