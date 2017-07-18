-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
C = ffi.C

core.define 'GtkTargetEntry', {
  new: (target, flags, info) ->
    flags = core.parse_flags('GTK_TARGET_', flags)
    ptr = C.gtk_target_entry_new target, flags, info
    ffi.gc ptr, C.gtk_target_entry_free

}, (def, target, flags = 0, info = 0) ->
  def.new target, flags, info
