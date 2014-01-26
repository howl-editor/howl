-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

ffi = require 'ffi'
C = ffi.C

auto_require = (module, name) ->
  name = name\gsub '%l%u', (match) ->
    match\gsub '%u', (upper) -> '_' .. upper\lower!
  name = name\lower!
  require "ljglibs.#{module}.#{name}"

{
  define: (name, spec, constructor) ->
    mt = spec.meta or {}
    props = spec.properties or {}

    if spec.constants
      pfx = spec.constants.prefix or ''
      for c in *spec.constants
        full = "#{pfx}#{c}"
        spec[c] = C[full]
        spec[full] = C[full]

    mt.__index = (o, k) ->
      prop = props[k]
      return prop o if prop
      spec[k]

    ffi.metatype name, mt
    spec = setmetatable(spec, __call: constructor) if constructor
    spec

  auto_loading: (name, def) ->
    setmetatable def, __index: (t, k) -> auto_require name, k
}
