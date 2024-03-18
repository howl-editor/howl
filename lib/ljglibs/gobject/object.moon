ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
core = require 'ljglibs.core'
types = require 'ljglibs.types'
signal = require 'ljglibs.gobject.signal'

C, ffi_cast, ffi_new = ffi.C, ffi.cast, ffi.new
lua_value = types.lua_value

ffi.cdef "
GType howl_gobject_type_from_instance(gpointer instance)
"

core.define 'GObject', {
  properties: {
    gtype: => C.howl_gobject_type_from_instance(@)
  }

  new: (type) ->
    error 'Undefined gtype passed in', 2 if type == 0 or type == nil
    C.g_object_new type

  ref: (o) ->
    return nil if o == nil
    C.g_object_ref o
    o

  ref_sink: (o) ->
    return nil if o == nil
    C.g_object_ref_sink o
    o

  unref: (o) ->
    return nil if o == nil
    C.g_object_unref o
    nil

  clear_object: (o) ->
    arr = ffi_new 'GObject *[1]'
    arr[0] = o
    C.g_clear_object arr
    print "o: #{o}"

  get_typed: (k, type) =>
    ret = ffi_new "#{type}[1]"
    C.g_object_get @, k, ret, nil
    r = ret[0]
    return nil if r == nil
    r = lua_value type, r

    if type\match '^%u.*%*$' -- Object * pointer
      C.g_object_ref r
      return ffi.gc(r, C.g_object_unref)

    r

  set_typed: (k, type, v) =>
    C.g_object_set @, k, ffi_cast(type, v), nil

  connect: (signal_name, handler, ...) =>
    signal.connect @, signal_name, handler, ...

}, (spec, type) -> spec.new type

