core = require 'ljglibs.core'
require 'ljglibs.cdefs.gobject'
ffi = require 'ffi'
C = ffi.C

core.auto_loading 'gobject', {
  gc_ptr: (o) ->
    return nil if o == nil

    if C.g_object_is_floating(o) != 0
      C.g_object_ref_sink(o)

    ffi.gc(o, C.g_object_unref)

  ref_ptr: (o) ->
    return nil if o == nil

    C.g_object_ref o
    ffi.gc(o, C.g_object_unref)
}
