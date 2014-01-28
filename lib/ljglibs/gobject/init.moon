core = require 'ljglibs.core'
require 'ljglibs.cdefs.gobject'
ffi = require 'ffi'
C = ffi.C

core.auto_loading 'gobject', {
  gc_ptr: (o) ->
    return nil if o == nil
    ffi.gc(o, C.g_object_unref)
}
