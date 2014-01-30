-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

signal = require 'ljglibs.gobject.signal'
Type = require 'ljglibs.gobject.type'
ffi = require 'ffi'
C, ffi_cast = ffi.C, ffi.cast
unpack = table.unpack

defs = {}
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

snake_case = (s) ->
  s = s\gsub '%l%u', (match) ->
    match\gsub '%u', (upper) -> '_' .. upper\lower!
  s = s\gsub '^%u%u%l', (pfx) -> pfx\sub(1,1)\lower! .. '_' .. pfx\sub(2)
  s\lower!

auto_require = (module, name) ->
  require "ljglibs.#{module}.#{snake_case name}"

force_type_init = (name) ->
  snake_name = snake_case name
  type_f = "#{snake_name}_get_type"
  ffi.cdef "GType #{type_f}();"
  status, gtype = pcall -> C[type_f]!
  status and gtype or nil

dispatch = (def, base, o, k, cast) ->
  props = def.properties
  o = cast(o) if cast
  if props
    prop = props[k]
    return prop o if prop

  v = rawget def, k
  if v
    if cast and type(v) == 'function'
      return (instance, ...) -> v o, ...
    return v

  if base
    dispatch base.def, base.base, o, k, base.cast

set_constants = (def) ->
  if def.constants
    pfx = def.constants.prefix or ''
    for c in *def.constants
      full = "#{pfx}#{c}"
      def[c] = C[full]
      def[full] = C[full]

cast = (gtype, v) ->
  c = casts[tonumber gtype]
  c and c(v) or v

set_signals = (name, def, gtype, instance_cast) ->
  query_info = Type.query gtype
  return if query_info.class_size == 0
  type_class = Type.class_ref gtype
  ids = signal.list_ids gtype
  Type.class_unref type_class
  for id in *ids
    info = signal.query id, gtype
    name = 'on_' .. info.signal_name\gsub '-', '_'
    unless def[name]
      ret_type = info.return_type == base_types.gboolean and 'bool' or 'void'
      cb_type = "#{ret_type}#{info.n_params + 2}"
      def[name] = (instance, handler, ...) ->
        casting_handler = (...) ->
          n = select '#', ...
          args = {...}
          args[1] = instance_cast args[1]
          for i = 2, info.n_params + 1
            args[i] = cast info.param_types[i], args[i]

          handler unpack(args, 1, n)

        signal.connect cb_type, instance, info.signal_name, casting_handler, ...

{
  define: (name, spec, constructor) ->
    base = nil
    if name\find '<', 1
      name, base_name = name\match '(%S+)%s+<%s+(%S+)'
      base = defs[base_name]
      unless base
        error "Unknown base '#{base_name}' specified for '#{name}'"

    gtype = force_type_init name
    ctype = ffi.typeof "#{name} *"
    cast = (o) -> ffi_cast(ctype, o)

    meta_t = spec.meta or {}
    spec.properties or= {}
    set_constants spec
    set_signals name, spec, gtype, cast if gtype
    meta_t.__index = (o, k) -> dispatch spec, base, o, k

    ffi.metatype name, meta_t
    mt = __call: constructor, __index: base and base.def
    spec = setmetatable(spec, mt)
    casts[tonumber gtype] = cast if gtype
    defs[name] = {
      :base
      metatype: meta_t,
      def: spec,
      :cast
    }
    spec

  auto_loading: (name, def) ->
    set_constants def
    setmetatable def, __index: (t, k) -> auto_require name, k

  :cast
}
