ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'

C, ffi_string = ffi.C, ffi.string

{
  name: (gtype) ->
    n = C.g_type_name gtype
    if n != nil
      ffi_string n
    else
      nil

  from_name: (name) ->
    gtype = C.g_type_from_name name
    gtype != 0 and gtype or nil

  class_ref: (gtype) -> C.g_type_class_ref gtype
  class_unref: (type_class) -> C.g_type_class_unref type_class
  is_a: (gtype, is_a_type) -> C.g_type_is_a(gtype, is_a_type ) != 0
}
