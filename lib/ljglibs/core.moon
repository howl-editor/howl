-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C, ffi_cast = ffi.C, ffi.cast

defs = {}

auto_require = (module, name) ->
  name = name\gsub '%l%u', (match) ->
    match\gsub '%u', (upper) -> '_' .. upper\lower!
  name = name\lower!
  require "ljglibs.#{module}.#{name}"

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

{
  define: (name, spec, constructor) ->
    base = nil
    if name\find '<', 1
      name, base_name = name\match '(%S+)%s+<%s+(%S+)'
      base = defs[base_name]
      unless base
        error "Unknown base '#{base_name}' specified for '#{name}'"

    meta_t = spec.meta or {}
    spec.properties or= {}
    set_constants spec
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
