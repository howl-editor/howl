-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)
import Settings from howl
append = table.insert

local scopes
layer_defs = {'default': {}}
defs = {}
watchers = {}

saved_scopes = {''}

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
      status, ret = pcall callback, name, value, is_local
      if not status
        log.error 'Error invoking config watcher: ' .. ret

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
  error 'defaults not allowed' if def.defaults
  layer_defs[name] = moon.copy(def)
  layer_defs[name].defaults = {}

define
  name: 'persist_config'
  description: 'Whether to save the configuration values'
  type: 'boolean'
  default: true

define
  name: 'save_config_on_exit'
  description: 'Whether to automatically save the current configuration on exit'
  type: 'boolean'
  default: false
  scope: 'global'

load_config = (force=false, dir=nil) ->
  return if scopes and not force
  settings = Settings dir
  scopes = settings\load_system('config') or {}

local get

save_config = (dir=nil) ->
  return unless scopes
  settings = Settings dir
  scopes_copy = {}
  for scope, values in *saved_scopes
    values = scopes[scope]
    continue unless values
    persisted_values = nil
    if get 'persist_config', scope
      persisted_values = values
    else
      persisted_values = {'persist_config': values['persist_config']}

    empty = not next persisted_values
    if persisted_values and not empty
      scopes_copy[scope] = persisted_values

  settings\save_system('config', scopes_copy)

set = (name, value, scope='', layer='default') ->
  load_config! unless scopes

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

set_default = (name, value, layer='default') ->
  def = get_def name
  error "Unknown layer '#{layer}'" if not layer_defs[layer]
  value = convert def, value
  validate def, value

  layer_defs[layer].defaults[name] = value

  broadcast name, value, true

get_default = (name, layer='default') ->
  if layer_defs[layer].defaults
    return layer_defs[layer].defaults[name]

parent = (scope) ->
  pos = scope\rfind('/')
  return '' unless pos
  return scope\sub(1, pos - 1)

local _get
_get = (name, scope, layers) ->
  values = scopes[scope] and scopes[scope][name]
  values = {} if values == nil

  if scope == ''
    for _layer in *layers
      value = values[_layer]
      return value if value != nil
      value = get_default name, _layer
      return value if value != nil
  else
    for _layer in *layers
      value = values[_layer]
      return value if value != nil

  if scope != ''
    return _get(name, parent(scope), layers)

  def = defs[name]
  return def.default if def

get = (name, scope='', layer='default') ->
  load_config! unless scopes

  current_layer = layer
  layers = {layer}
  while current_layer
    current_layer = layer_defs[current_layer].parent
    append layers, current_layer
  if layers[#layers] != 'default'
    append layers, 'default'

  _get name, scope, layers

reset = ->
  scopes = {}
  for _, layer_def in pairs layer_defs
    layer_def.defaults = {}

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

merge = (scope, target_scope) ->
  if scopes[scope]
    scopes[target_scope] or= {}
    target = scopes[target_scope]
    source = scopes[scope]
    for layer, layer_config in pairs source
      if target[layer]
        for name, value in pairs layer_config
          target[layer][name] = value
      else
        target[layer] = moon.copy layer_config

replace = (scope, target_scope) ->
  scopes[target_scope] = {}
  merge scope, target_scope

delete = (scope) ->
  error 'Cannot delete global scope' if scope == ''
  scopes[scope] = nil

config = {
  :definitions
  :load_config
  :save_config
  :define
  :define_layer
  :set
  :set_default
  :get
  :watch
  :reset
  :proxy
  :replace
  :merge
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
