ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'
core = require 'ljglibs.core'

C, ffi_cast, ffi_new, ffi_string = ffi.C, ffi.cast, ffi.new, ffi.string
gpointer_t = ffi.typeof 'gpointer'

lconverters = {
  gboolean: (v) -> v != 0

  'gchar*': (v) ->
    return nil if v == nil
    s = ffi_string v
    C.g_free v
    s
}

core.define 'GObject', {
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

  get_typed: (k, type) =>
    ret = ffi_new "#{type}[1]"
    C.g_object_get @, k, ret
    r = ret[0]
    return nil if r == nil
    converter = lconverters[type]
    return converter r if converter

    if type\match '^%u.*%*$' -- Object * pointer
      return ffi.gc(r, C.g_object_unref)

    r

  set_typed: (k, type, v) =>
    C.g_object_set @, k, ffi_cast(type, v)

}, (spec, type) -> spec.new type

