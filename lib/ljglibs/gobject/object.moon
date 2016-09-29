ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
core = require 'ljglibs.core'
types = require 'ljglibs.types'

C, ffi_cast, ffi_new = ffi.C, ffi.cast, ffi.new
lua_value = types.lua_value

core.define 'GObject', {
  new: (type, ...) ->
    error 'Undefined gtype passed in', 2 if type == 0 or type == nil
    C.g_object_new type, ...

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

}, (spec, type, ...) -> spec.new type, ...

