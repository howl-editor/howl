-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

signal = require 'ljglibs.gobject.signal'
types = require 'ljglibs.types'
Type = require 'ljglibs.gobject.type'
ffi = require 'ffi'
bit = require 'bit'
C, ffi_cast = ffi.C, ffi.cast
pack, unpack = table.pack, table.unpack

defs = {}

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

dispatch_property = (o, prop, k, v) ->
  if type(prop) == 'string'
    k = k\gsub '_', '-'
    return o\get_typed k, prop unless v != nil
    o\set_typed k, prop, v.value
  else
    if v != nil
      setter = prop.set
      error "Attempt to set read-only property: '#{k}'" unless setter
      setter o, v.value
    else
      return prop o if type(prop) == 'function'
      return prop.get o

dispatch = (def, base, o, k, v, instance_cast) ->
  o = instance_cast(o) if instance_cast
  prop = def.properties[k]
  if prop
    return dispatch_property o, prop, k, v

  unless v != nil
    def_v = rawget def, k
    if def_v
      if instance_cast and type(def_v) == 'function'
        return (instance, ...) -> def_v o, ...
      return def_v

  if base
    dispatch base.def, base.base, o, k, v, base.cast

set_constants = (def) ->
  if def.constants
    pfx = def.constants.prefix or ''
    for c in *def.constants
      full = "#{pfx}#{c}"
      def[c] = C[full]
      def[full] = C[full]

setup_signals = (name, def, gtype, instance_cast) ->
  ids = signal.list_ids gtype
  for id in *ids
    info = signal.query id, gtype
    name = 'on_' .. info.signal_name\gsub '-', '_'
    unless def[name]
      ret_type = info.return_type == types.base_types.gboolean and 'bool' or 'void'
      cb_type = "#{ret_type}#{info.n_params + 2}"
      def[name] = (instance, handler, ...) ->
        unless handler
          error "`nil` handler passed as handler for '#{name}'"

        casting_handler = (...) ->
          args = pack ...
          args[1] = instance_cast args[1]
          for i = 2, info.n_params + 1
            args[i] = types.cast info.param_types[i], args[i]

          handler unpack(args, 1, args.n)

        signal.connect cb_type, instance, info.signal_name, casting_handler, ...

construct = (spec, no_container, constructor, ...) ->
  args = {...}
  last = args[#args]
  if type(last) == 'table' and not no_container
    inst = constructor spec, unpack(args, 1, #args - 1)
    inst[k] = v for k,v in pairs last when type(k) != 'number'
    for child in *last
      properties = nil
      if type(child) == 'table'
        properties = child
        child = child[1]

      inst\add child

      if properties
        props = inst\properties_for(child)
        props[k] = v for k, v in pairs properties when type(k) != 'number'
    inst
  else
    constructor spec, ...

{
  define: (name, spec, constructor, options = {}) ->
    base = nil
    if name\find '<', 1
      name, base_name = name\match '(%S+)%s+<%s+(%S+)'
      base = defs[base_name]
      unless base
        error "Unknown base '#{base_name}' specified for '#{name}'"

    gtype = force_type_init name
    ctype = ffi.typeof "#{name} *"
    cast = (o) -> ffi_cast(ctype, o)
    types.register_cast name, gtype, ctype if gtype

    meta_t = spec.meta or {}
    meta_t.__index = (o, k) -> dispatch spec, base, o, k
    meta_t.__newindex = (o, k, v) -> dispatch spec, base, o, k, value: v
    ffi.metatype name, meta_t
    spec.properties or= {}
    set_constants spec
    spec.__type = name

    if gtype and Type.query(gtype).class_size != 0
      type_class = Type.class_ref gtype
      setup_signals name, spec, gtype, cast
      Type.class_unref type_class

    mt = __index: base and base.def
    if constructor
      no_container = meta_t.__is_container == false
      mt.__call = (t, ...) -> construct t, no_container, constructor, ...

    spec = setmetatable(spec, mt)

    defs[name] = {
      :base
      metatype: meta_t,
      def: spec,
      cast: not options.no_cast and cast
      :options
    }
    spec

  auto_loading: (name, def) ->
    set_constants def
    setmetatable def, __index: (t, k) -> auto_require name, k

  bit_flags: (def, prefix = '', value) ->
    setmetatable { :value, :def }, __index: (t, k) ->
      kv = def["#{prefix}#{k}"]
      error "Unknown member '#{k}'" unless kv
      bit.band(tonumber(t.value), tonumber(kv)) != 0

  parse_flags: (prefix, flags) ->
    return 0 unless flags
    return flags if type(flags) != 'table'
    f = 0
    f = bit.bor(f, C["#{prefix}#{v}"]) for v in *flags
    f

  optional: (v) ->
    if v == nil
      nil
    else
      v
}
