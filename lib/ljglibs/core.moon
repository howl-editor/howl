-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C = ffi.C

auto_require = (module, name) ->
  name = name\gsub '%l%u', (match) ->
    match\gsub '%u', (upper) -> '_' .. upper\lower!
  name = name\lower!
  require "ljglibs.#{module}.#{name}"

set_constants = (def) ->
  if def.constants
    pfx = def.constants.prefix or ''
    for c in *def.constants
      full = "#{pfx}#{c}"
      def[c] = C[full]
      def[full] = C[full]

{
  define: (name, spec, constructor) ->
    mt = spec.meta or {}
    props = spec.properties or {}
    set_constants spec

    mt.__index = (o, k) ->
      prop = props[k]
      return prop o if prop
      spec[k]

    ffi.metatype name, mt
    spec = setmetatable(spec, __call: constructor) if constructor
    spec

  auto_loading: (name, def) ->
    set_constants def
    setmetatable def, __index: (t, k) -> auto_require name, k
}
