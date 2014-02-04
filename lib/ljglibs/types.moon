Type = require 'ljglibs.gobject.type'
ffi = require 'ffi'
require 'ljglibs.cdefs.gtk'

C, ffi_cast, ffi_string = ffi.C, ffi.cast, ffi.string

casts = {}
base_types = {}

for base_type in *{
  'gchar', 'glong', 'gulong', 'gint', 'guint', 'gint64', 'guint64', 'gboolean',
  'gpointer', 'guint64', 'gdouble', 'GObject'
}
  ctype = ffi.typeof base_type
  gtype = Type.from_name base_type
  casts[tonumber gtype] = (v) -> ffi_cast ctype, v
  base_types[base_type] = gtype

lua_converters = {
  gboolean: (v) -> v != 0

  'gchar*': (v) ->
    return nil if v == nil
    s = ffi_string v
    C.g_free v
    s
}

{
  :base_types

  lua_value: (type, v) ->
    return nil if v == nil
    converter = lua_converters[type]
    return converter v if converter
    v

  cast: (gtype, v) ->
    c = casts[tonumber gtype]
    c and c(v) or v

  cast_widget_ptr: (ptr) ->
    return nil if ptr == nil
    name = ffi_string C.gtk_widget_get_name ptr
    cast = casts[name]
    cast and cast(ptr) or ptr

  register_cast: (name, gtype, ctype) ->
    ctype = ffi.typeof ctype if type(ctype) == 'string'
    cast = (v) -> ffi_cast ctype, v
    casts[tonumber gtype] = cast
    casts[name] = cast
}
