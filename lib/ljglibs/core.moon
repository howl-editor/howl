-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

signal = require 'ljglibs.gobject.signal'
Type = require 'ljglibs.gobject.type'
ffi = require 'ffi'
C, ffi_cast = ffi.C, ffi.cast

defs = {}

base_types = {
  gobject: Type.from_name 'GObject'
  gboolean: Type.from_name 'gboolean'
  void: Type.from_name 'void'
}

snake_case = (s) ->
  s = s\gsub '%l%u', (match) ->
    match\gsub '%u', (upper) -> '_' .. upper\lower!
  s\lower!

auto_require = (module, name) ->
  require "ljglibs.#{module}.#{snake_case name}"

force_type_init = (name) ->
  snake_name = snake_case name
  type_f = "#{snake_name}_get_type"
  ffi.cdef "GType #{type_f}();"
  status = pcall -> C[type_f]!

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

set_signals = (name, def) ->
  gtype = Type.from_name name
  return if not gtype or not Type.is_a gtype, base_types.gobject

  ids = signal.list_ids gtype
  for id in *ids
    info = signal.query id, gtype
    name = 'on_' .. info.signal_name\gsub '-', '_'
    unless def[name]
      ret_type = info.return_type == base_types.gboolean and 'bool' or 'void'
      cb_type = "#{ret_type}#{info.n_params + 2}"
      def[name] = (instance, handler, ...) ->
        signal.connect cb_type, instance, info.signal_name, handler, ...

{
  define: (name, spec, constructor) ->
    base = nil
    if name\find '<', 1
      name, base_name = name\match '(%S+)%s+<%s+(%S+)'
      base = defs[base_name]
      unless base
        error "Unknown base '#{base_name}' specified for '#{name}'"

    force_type_init name
    meta_t = spec.meta or {}
    spec.properties or= {}
    set_constants spec
    set_signals name, spec
    meta_t.__index = (o, k) -> dispatch spec, base, o, k

    ffi.metatype name, meta_t
    mt = __call: constructor, __index: base and base.def
    spec = setmetatable(spec, mt)
    ctype = ffi.typeof "#{name} *"
    defs[name] = {
      :base
      metatype: meta_t,
      def: spec,
      cast: (o) -> ffi_cast(ctype, o)
    }
    spec

  auto_loading: (name, def) ->
    set_constants def
    setmetatable def, __index: (t, k) -> auto_require name, k
}
