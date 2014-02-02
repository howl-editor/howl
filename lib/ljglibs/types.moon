ffi = require 'ffi'
-- require 'ljglibs.cdefs.gobject'
-- core = require 'ljglibs.core'

C, ffi_cast, ffi_new, ffi_string = ffi.C, ffi.cast, ffi.new, ffi.string
-- gpointer_t = ffi.typeof 'gpointer'

lua_converters = {
  gboolean: (v) -> v != 0

  'gchar*': (v) ->
    return nil if v == nil
    s = ffi_string v
    C.g_free v
    s
}

{
  lua_value: (type, v) ->
    return nil if v == nil
    converter = lua_converters[type]
    return converter v if converter
    v

}
