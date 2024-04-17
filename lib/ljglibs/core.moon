-- Copyright 2014-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

signal = require 'ljglibs.gobject.signal'
types = require 'ljglibs.types'
Type = require 'ljglibs.gobject.type'
ffi = require 'ffi'
bit = require 'bit'
C, ffi_cast = ffi.C, ffi.cast

defs = {}

snake_case = (s) ->
  s = s\gsub '%l%u', (match) ->
    match\gsub '%u', (upper) -> '_' .. upper\lower!
  s = s\gsub '%u%u+%l', (match) ->
    match\match('%u')\lower! .. '_' .. match\sub(#match - 1)
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

setup_signals = (def, gtype, instance_cast) ->
  def['connect_for'] = (g_instance, lua_ref, signal_name, handler, ...) ->
    signal.connect_for lua_ref, g_instance, signal_name, handler, ...

  -- deprecated below
  ids = signal.list_ids gtype
  for id in *ids
    info = signal.query id, gtype

    name = 'on_' .. info.signal_name\gsub '-', '_'
    unless def[name]
      def[name] = (instance, handler, ...) ->
        print " XXX deprecated signal handler: #{name}"
        unless handler
          error "`nil` handler passed as handler for '#{name}'"

        cb_handle = signal.connect_by_info instance, info, handler, ...
        cb_handle

construct = (spec, auto_properties, constructor, ...) ->
  args = {...}
  last = args[#args]
  if type(last) == 'table' and auto_properties
    inst = constructor spec, unpack(args, 1, #args - 1)
    -- assign any eventual properties
    inst[k] = v for k,v in pairs last when type(k) != 'number'
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
    gtype or= Type.from_name(name)
    ctype = ffi.typeof "#{name} *"

    if gtype
      Type.ensure(gtype)
      types.register_cast name, gtype, ctype if gtype
    -- print "core: #{name} = #{gtype}, #{other_type}"
    cast = (o) -> ffi_cast(ctype, o)

    meta_t = spec.meta or {}
    meta_t.__index = (o, k) -> dispatch spec, base, o, k
    meta_t.__newindex = (o, k, v) -> dispatch spec, base, o, k, value: v
    ffi.metatype name, meta_t
    spec.properties or= {}
    set_constants spec
    spec.__type = name
    spec.__cast = cast

    if gtype and Type.query(gtype).class_size != 0
      type_class = Type.class_ref gtype
      setup_signals spec, gtype, cast
      Type.class_unref type_class

    mt = __index: base and base.def
    if constructor
      auto_properties = not meta_t.__plain_constructor == true
      mt.__call = (t, ...) -> construct t, auto_properties, constructor, ...

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
