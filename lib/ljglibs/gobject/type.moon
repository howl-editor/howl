ffi = require 'ffi'
require 'ljglibs.cdefs.gobject'

C, ffi_string = ffi.C, ffi.string

{
  name: (type) -> ffi_string C.g_type_name type
  from_name: (name) -> C.g_type_from_name name
}
