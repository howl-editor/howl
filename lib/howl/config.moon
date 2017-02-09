-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
append = table.insert

scopes = {}
layer_defs = {'default': {}}
defs = {}
watchers = {}

predefined_types =
  boolean: {
    options: { true, false }
    convert: (value) ->
      return value if type(value) == 'boolean'
      return true if value == 'true'
      return false if value == 'false'
      value
  },

  number: {
    convert: (value) -> tonumber(value) or tonumber(tostring(value)) or value
    validate: (value) -> type(value) == 'number'
  },

  string: {
    convert: (value) -> tostring value
  }

  string_list: {
    convert: (value) ->
      what = type(value)
      if what == 'table'
        [tostring(v) for v in *value]
      elseif what == 'string' and value\contains ','
        [v.stripped for v in value\gmatch '[^,]+']
      elseif what == 'string' and value.is_blank
        {}
      else
        { tostring value }

    validate: (value) -> type(value) == 'table'
    tostring: (value) ->
      type(value) == 'table' and table.concat(value, ', ') or tostring value
  }

broadcast = (name, value, is_local) ->
  callbacks = watchers[name]
  if callbacks
    for callback in *callbacks
      howl.util.safecall 'Error invoking config watcher', callback, name, value, is_local

get_def = (name) ->
  def = defs[name]
  error 'Undefined variable "' .. name .. '"', 2 if not def
  def

validate = (def, value) ->
  return if value == nil

  def_valid = def.validate and def.validate(value)
  if def_valid != nil
    if not def_valid
      error "Illegal option '#{value}' for '#{def.name}'"
    else
      return true

  if def.options
    options = type(def.options) == 'table' and def.options or def.options!
    for option in *options
      option = option[1] if type(option) == 'table'
      return if option == value

    error "Illegal option '#{value}' for '#{def.name}'"

convert = (def, value) ->
  if def.convert
    new_value = def.convert(value)
    return new_value if new_value != nil
  value

definitions = setmetatable {},
  __index: (_, k) -> defs[k]
  __newindex: -> error 'Attempt to write to read-only table `.definitions`'
  __pairs: -> pairs defs

define = (var = {}) ->
  for field in *{'name', 'description'}
    error '`' .. field .. '` missing', 2 if not var[field]

  if var.scope and var.scope != 'local' and var.scope != 'global'
    error 'Unknown scope "' .. var.scope .. '"', 2

  if var.type_of
    var = moon.copy var
    predef = predefined_types[var.type_of]
    error('Unknown type"' .. var.type_of .. '"', 2) if not predef
    for k,v in pairs predef
      var[k] = v unless var[k] != nil

  defs[var.name] = var
  broadcast var.name, var.default, false

define_layer = (name, def={}) ->
  layer_defs[name] = moon.copy(def)

set = (name, value, scope='', layer='default') ->
  def = get_def name

  error "Unknown layer '#{layer}'" if not layer_defs[layer]

  if def.scope
    if def.scope == 'local' and scope == ''
      error 'Attempt to set a global value for local variable "' .. name .. '"', 2
    if def.scope == 'global' and scope != ''
     error 'Attempt to set a local value for global variable "' .. name .. '"', 2

  value = convert def, value
  validate def, value

  unless scopes[scope]
    scopes[scope] = {}
  unless scopes[scope][name]
    scopes[scope][name] = {}

  scopes[scope][name][layer] = value

  broadcast name, value, (scope != '' or layer != 'default')

parent = (scope) ->
  pos = scope\rfind('/')
  return '' unless pos
  return scope\sub(1, pos - 1)

get = (name, scope='', layer) ->
  values = scopes[scope] and scopes[scope][name]

  if values
    current_layer = layer
    while current_layer
      value = values[current_layer]
      if value != nil
        return value
      current_layer = layer_defs[current_layer].parent
    if values['default'] != nil
      return values['default']

  if scope != ''
    return get(name, parent(scope), layer)

  def = defs[name]
  return def.default if def

reset = -> scopes = {}

watch = (name, callback) ->
  list = watchers[name]
  if not list
    list = {}
    watchers[name] = list
  append list, callback

proxy_mt = {
  __index: (proxy, key) -> get(key, proxy._scope, proxy._read_layer)
  __newindex: (proxy, key, value) -> set(key, value, proxy._scope, proxy._write_layer)
}

proxy = (scope, write_layer='default', read_layer=write_layer) ->
  proxy = {
    clear: => scopes[@_scope] = {}
    _scope: scope
    _write_layer: write_layer
    _read_layer: read_layer
  }
  setmetatable proxy, proxy_mt

copy = (scope, new_scope) ->
  scopes[new_scope] = {}
  if scopes[scope]
    for k, v in pairs scopes[scope]
      scopes[new_scope][k] = moon.copy v

delete = (scope) ->
  error 'Cannot delete global scope' if scope == ''
  scopes[scope] = nil

config = {
  :definitions
  :define
  :define_layer
  :set
  :get
  :watch
  :reset
  :proxy
  :copy
  :delete
}

return setmetatable config, {
  __index: (t, k) -> rawget(config, k) or get k
  __newindex: (t, k, v) ->
    if rawget config, k
      config[k] = v
    else
      set k, v
}
