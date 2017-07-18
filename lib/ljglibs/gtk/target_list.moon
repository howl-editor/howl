-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
C = ffi.C

core.define 'GtkTargetList', {
  new: () ->
    ptr = C.gtk_target_list_new nil, 0
    ffi.gc ptr, C.gtk_target_list_unref

  add: (target, flags = 0, info = 0) =>
    flags = core.parse_flags('GTK_TARGET_', flags)
    C.gtk_target_list_add @, target, flags, info

}, (def, targets) ->
  def.new targets
