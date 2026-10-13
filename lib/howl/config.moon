-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:Settings} = howl
{:json} = howl.util
append = table.insert

-- Holds configuration values in a nested table structure.
-- Top level key is the scope name, second level key is the variable name,
-- third level key is the layer. E.g.
-- scopes['file/home/user/a']['indent']['mode:moonscript'] = 4
--
-- The scope is a string that represents a node in a tree structure. It uses
-- a slash based syntax like filesystem paths. Scopes for files
-- use the 'file/' prefix followed by actual filesystem path.
-- The layer is one of layer_defs (below). All modes automatically
-- add a layer named "mode:{mode_name}" (e.g. 'mode:moonscript').
--
-- Note that *all* configuration values (except defaults) are stored in this
-- table while the app is running. The defaults are stored in the configuration
-- definitions (`defs` below).
local scopes

-- registry of all layers - the default layer has no parents
layer_defs = {'default': {}}

-- registry of all configuration variable definitions
defs = {}

-- map of variable name to list of watching functions
watchers = {}

-- The global scope is saved as `system/config.json` in the settings
-- directory. Other scopes are saved only once loaded with load_scope, such as
-- those of projects. This maps such a scope to its `file`, and the JSON it
-- `saved` or loaded, so that unchanged files aren't rewritten.
scope_files = {}

-- Set when the global configuration failed to load, to not overwrite it
global_load_failed = false

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

  positive_number: {
    convert: (value) -> tonumber(value) or tonumber(tostring(value)) or value
    validate: (value) -> type(value) == 'number' and value >= 0
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
  -- Check if value is valid for a variable definition
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

-- A read-only view of current configuration variable definitions.
definitions = setmetatable {},
  __index: (_, k) -> defs[k]
  __newindex: -> error 'Attempt to write to read-only table `.definitions`'
  __pairs: -> pairs defs

define = (var = {}) ->
  -- Define a new configuration variable.
  -- The definition table includes
  --   name: String name for this variable (no spaces)
  --   description: Free form text description
  --   scope: (optional) 'global' or 'local'
  --   type_of: (optional) One of the predefined_types key above
  --   options: (optional) List of valid values, or function that returns such
  --            a list. When provided, only a value from this list may be set
  --            this variable.
  --   default: (optional) Default value for this variable
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
  -- Register a new layer identified by string name.
  -- Once registered, the layer is available system wide and any
  -- configuration variable can be set for this layer.
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

-- Saved configuration has the values of a scope, as
-- `{config: {name: value}, modes: {mode_name: {name: value}}}` for the default
-- layer and the mode layers, plus `layers: {layer: {name: value}}` for any
-- other layers. `to_data` converts the values of a scope to this, and
-- `from_data` back again.
to_data = (values) ->
  data = {}
  section = (key, sub) ->
    data[key] or= {}
    return data[key] unless sub
    data[key][sub] or= {}
    data[key][sub]

  for name, layers in pairs values
    for layer, value in pairs layers
      mode_name = layer\match '^mode:(.+)$'
      vars = if layer == 'default'
        section 'config'
      elseif mode_name
        section 'modes', mode_name
      else
        section 'layers', layer
      vars[name] = value

  data

from_data = (data) ->
  object = (v, what) ->
    error "#{what} is not an object", 0 unless type(v) == 'table'
    for k in pairs v
      error "#{what} is not an object", 0 unless type(k) == 'string'
    v

  values = {}
  add = (vars, layer, what) ->
    for name, value in pairs object(vars, what)
      values[name] or= {}
      values[name][layer] = value

  object data, 'The configuration'
  add data.config, 'default', '`config`' if data.config != nil
  if data.modes != nil
    for mode_name, vars in pairs object(data.modes, '`modes`')
      add vars, "mode:#{mode_name}", "`modes.#{mode_name}`"
  if data.layers != nil
    for layer, vars in pairs object(data.layers, '`layers`')
      add vars, layer, "`layers.#{layer}`"

  values

read_config = (dir) ->
  data = Settings(dir)\load_system 'config'
  return {} unless data
  -- before JSON the saved configuration was the scopes table itself
  return data if type(data) == 'table' and data[''] != nil
  {'': from_data data}

load_config = (force=false, dir=nil) ->
  -- Load the configuration from the filesystem.
  return if scopes and not force
  scope_files = {}
  status, ret = pcall read_config, dir
  scopes = status and ret or {}
  global_load_failed = not status
  log.error "Failed to load the configuration: #{ret}" unless status

local get

-- the values of scope to save: all of them, unless persist_config is false
persisted = (scope) ->
  values = scopes[scope] or {}
  return values if get 'persist_config', scope
  {persist_config: values.persist_config}

save_scope = (scope, scope_file) ->
  {:file} = scope_file
  data = to_data persisted(scope)
  text = json.encode data
  return if text == scope_file.saved
  return if not next(data) and not file.exists
  file.parent\mkdir_p! unless file.parent.exists
  file.contents = text .. '\n'
  scope_file.saved = text

save_config = (dir=nil) ->
  -- Save the current configuration to the filesystem: the global scope, and
  -- the scopes loaded with load_scope to their files. Raises an error
  -- listing whatever failed, after saving the rest.
  return unless scopes
  errors = {}
  for scope, scope_file in pairs scope_files
    status, err = pcall save_scope, scope, scope_file
    append errors, "Failed to save #{scope_file.file}: #{err}" unless status

  if global_load_failed
    append errors, 'Not saving the global configuration, since it failed to load'
  else
    status, err = pcall -> Settings(dir)\save_system 'config', to_data(persisted '')
    append errors, "Failed to save the global configuration: #{err}" unless status

  error table.concat(errors, '\n'), 2 if #errors > 0

-- the values of the configuration file, by name and layer, or nil and an
-- error message if it failed to load
read_scope_file = (file) ->
  return {} unless file.exists
  status, ret = pcall -> from_data json.decode(file.contents)
  return nil, ret unless status
  ret

-- sets the values for scope that aren't already set, converted and validated
-- if their variables are defined, and has save_config save the scope to file
apply_scope_values = (scope, file, values) ->
  scopes[scope] or= {}
  target = scopes[scope]
  applied = {}
  for name, layers in pairs values
    def = defs[name]
    for layer, value in pairs layers
      continue if target[name] and target[name][layer] != nil
      if def
        if def.scope == 'global'
          log.error "#{file}: '#{name}' can only be set globally"
          continue

        status, err = pcall ->
          value = convert def, value
          validate def, value
        unless status
          log.error "#{file}: #{tostring(err)\gsub('^[^:]*:%d+: ', '')}"
          continue

      target[name] or= {}
      target[name][layer] = value
      append applied, {:name, :value}

  scope_files[scope] = :file, saved: json.encode(to_data persisted(scope))
  applied

load_scope = (scope, file) ->
  -- Load the values for `scope` from the JSON configuration `file`, keeping
  -- any values already set for the scope, and have save_config save the
  -- scope's values there. A file that fails to load is never saved, and a
  -- scope already loaded is left as is.
  load_config! unless scopes
  return if scope_files[scope]
  values, err = read_scope_file file
  unless values
    log.error "Failed to load #{file}: #{err}"
    return

  for v in *apply_scope_values scope, file, values
    broadcast v.name, v.value, true

reload_scope = (scope, file) ->
  -- Replace the values for `scope` with those in `file`, loaded as for
  -- load_scope. If the file fails to load the values are kept, but are no
  -- longer saved there.
  load_config! unless scopes
  values, err = read_scope_file file
  unless values
    scope_files[scope] = nil
    log.error "Failed to load #{file}: #{err}"
    return

  old = scopes[scope] or {}
  scopes[scope] = {}
  for v in *apply_scope_values scope, file, values
    broadcast v.name, v.value, true

  new = scopes[scope]
  for name, layers in pairs old
    for layer in pairs layers
      broadcast name, nil, true unless new[name] and new[name][layer] != nil

broadcast_config = ->
  -- broadcasts all values stores in scopes - useful after load_config
  return unless scopes
  -- scopes is a deeply nested table containing: scopes[scope][name][layer] = value
  for scope, scope_item in pairs scopes
    for name, name_item in pairs scope_item
      for layer, value in pairs name_item
        broadcast name, value, (scope != '' or layer != 'default')

set = (name, value, scope='', layer='default') ->
  -- Set the value of a configuration variabled named `name` to `value`
  -- for the specified scope and layer.
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

  -- store the value in the scope table
  scopes[scope][name][layer] = value

  broadcast name, value, (scope != '' or layer != 'default')

set_default = (name, value, layer='default') ->
  -- Set a default value for a configuration variable for a layer.
  -- This is in addition to the default provided in define(). The main
  -- purpose is to set default values for specific layers.
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
  -- Given a scope string, return it's parent scope string
  pos = scope\rfind('/')
  return '' unless pos
  return scope\sub(1, pos - 1)

local _get
_get = (name, scope, layers) ->
  -- Internal logic for getting the value of a configuration variable
  -- To get a value we need the variable name, a scope and a *list* of layers
  -- to search.
  values = scopes[scope] and scopes[scope][name]
  values = {} if values == nil

  if scope == ''
    -- top level, this is the global scope
    for _layer in *layers
      value = values[_layer]
      return value if value != nil
      -- for each layer, also check layer defaults
      value = get_default name, _layer
      return value if value != nil
  else
    -- a non-global scope - just check the layers but not the layer defaults
    for _layer in *layers
      value = values[_layer]
      return value if value != nil

  if scope != ''
    -- if we didn't find any value at this scope, check the parent recursively
    return _get(name, parent(scope), layers)

  -- finally, if no value was found, check the defined default
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
  -- Clear all configuration values and layer defaults
  scopes = {}
  scope_files = {}
  global_load_failed = false
  for _, layer_def in pairs layer_defs
    layer_def.defaults = {}

watch = (name, callback) ->
  list = watchers[name]
  if not list
    list = {}
    watchers[name] = list
  append list, callback


-- Proxy config objects are used to provide a convinient API to get and set
-- values *at a specific scope and layer*. E.g. these are used in
-- `buffer.config.indent = 4` to set a value at a specific scope associated with
-- the buffer.

proxy_mt = {
  __index: (proxy, key) -> get(key, proxy.scope, proxy._read_layer)
  __newindex: (proxy, key, value) -> set(key, value, proxy.scope, proxy._write_layer)
}

local proxy
proxy = (scope, write_layer='default', read_layer=write_layer) ->
  _proxy = {
    clear: => scopes[@scope] = {}
    for_layer: (layer) -> proxy scope, layer
    scope: scope
    layer: write_layer
    _write_layer: write_layer
    _read_layer: read_layer
  }
  setmetatable _proxy, proxy_mt

scope_for_file = (file) -> 'file'..file

for_file = (file) -> proxy scope_for_file file

for_layer = (layer) -> proxy '', layer  -- global scope

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
  :load_scope
  :reload_scope
  :broadcast_config
  :define
  :define_layer
  :set
  :set_default
  :get
  :watch
  :reset
  :proxy
  :scope_for_file
  :for_file
  :for_layer
  :replace
  :merge
  :delete
  :validate
}

-- Allow getting and setting config values directly on this module.
return setmetatable config, {
  __index: (t, k) -> rawget(config, k) or get k
  __newindex: (t, k, v) ->
    if rawget config, k
      config[k] = v
    else
      set k, v
}
