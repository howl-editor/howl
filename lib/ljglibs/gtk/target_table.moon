-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
ffi_new = ffi.new
require 'ljglibs.cdefs.gdk'
core = require 'ljglibs.core'
C = ffi.C

core.define 'GtkTargetTable', {
  new_from_list: (list) ->
    n_targets = ffi_new 'gint[1]'
    t_ptr = C.gtk_target_table_new_from_list list, n_targets
    ffi.gc(t_ptr, C.gtk_target_table_free), tonumber n_targets[1]
}
