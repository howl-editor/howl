-- Copyright 2014-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

core = require 'ljglibs.core'
require 'ljglibs.cdefs.gobject'
ffi = require 'ffi'
C = ffi.C

counters = {}

increase_counter = (name) ->
  counters[name] or= 0
  counters[name] += 1

release = (o) ->
  counters[o.__type] -= 1
  C.g_object_unref o


core.auto_loading 'gobject', {
  register_allocation: increase_counter
  register_deallocation: (name) ->  counters[name] -= 1

  gc_ptr: (o) ->
    return nil if o == nil
    increase_counter o.__type

    if C.g_object_is_floating(o) != 0
      C.g_object_ref_sink(o)

    ffi.gc(o, release)

  ref_ptr: (o) ->
    return nil if o == nil

    increase_counter o.__type
    C.g_object_ref o
    ffi.gc(o, release)

  get_allocations: ->
    allocations = [{name, count} for name, count in pairs counters when count > 0]
    table.sort allocations, (a, b) -> a[2] > b[2]
    return allocations
}
