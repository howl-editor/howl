-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'
core = require 'ljglibs.core'
gobject = require 'ljglibs.gobject'
require 'ljglibs.gtk.bin'

gc_ptr = gobject.gc_ptr

C = ffi.C

core.define 'GtkAlignment < GtkBin', {
  properties: {
    top_padding: 'guint'
    left_padding: 'guint'
    right_padding: 'guint'
    bottom_padding: 'guint'

    xalign: 'gfloat'
    xscale: 'gfloat'
    yalign: 'gfloat'
    yscale: 'gfloat'
  }

  new: (xalign = 0.5, yalign = 0.5, xscale = 1, yscale = 1) ->
    gc_ptr C.gtk_alignment_new xalign, yalign, xscale, yscale

  set: => (xalign, yalign, xscale, yscale)->
    C.gtk_alignment_set @, xalign, yalign, xscale, yscale

  set_padding: (padding_top, padding_bottom, padding_left, padding_right) =>
    C.gtk_alignment_set_padding @, padding_top, padding_bottom, padding_left, padding_right

  get_padding: =>
    ret = ffi.new 'guint[4]'
    C.gtk_alignment_get_padding @, ret, ret + 1, ret + 2, ret + 3
    ret[0], ret[1], ret[2], ret[3]

}, (spec, xalign, yalign, xscale, yscale)->
  spec.new xalign, yalign, xscale, yscale
