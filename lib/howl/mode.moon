import config from howl
import PropertyTable from howl.aux

class DefaultMode
  completers: { 'in_buffer' }

by_extension = {}
modes = {}
live = setmetatable {}, __mode: 'k'
mode_variables = {}

local by_name

instance_for_mode = (m) ->
  return live[m] if live[m]
  mode_config = config.local_proxy!

  if m.config
    mode_config[k] = v for k,v in pairs m.config

  mode_vars = mode_variables[m.name]
  if mode_vars
    mode_config[k] = v for k,v in pairs mode_vars

  error "Unknown mode specified as parent: '#{m.parent}'", 3 if m.parent and not modes[m.parent]
  parent = if m.name != 'default' then by_name m.parent or 'default'

  target = m.create!
  instance = setmetatable {
    name: m.name
    config: mode_config
    :parent
  }, {
    __index: (_, k) -> target[k] or parent and parent[k]
  }
  live[m] = instance
  instance

by_name = (name) ->
  modes[name] and instance_for_mode modes[name]

for_file = (file) ->
  return by_name('default') if not file
  ext = file.extension
  m = by_extension[ext] or modes['default']
  instance = m and instance_for_mode(m)
  error 'No mode available for "' .. file .. '"' if not instance
  instance

register = (mode = {}) ->
  error 'Missing field `name` for mode', 2 if not mode.name
  error 'Missing field `create` for mode', 2 if not mode.create

  extensions = mode.extensions or {}
  extensions = { extensions } if type(extensions) == 'string'
  by_extension[ext] = mode for ext in *(extensions or {})
  modes[mode.name] = mode

unregister = (name) ->
  mode = modes[name]
  if mode
    modes[name] = nil
    exts = [ext for ext, m in pairs by_extension when m == mode]
    by_extension[ext] = nil for ext in *exts
    live[mode] = nil

configure = (mode_name, variables) ->
  error 'Missing argument #1 (mode_name)', 2 unless mode_name
  error 'Missing argument #2 (variables)', 2 unless variables
  mode_vars = mode_variables[mode_name] or {}
  mode_vars[k] = v for k,v in pairs variables
  mode_variables[mode_name] = mode_vars

  -- update any already instantiated modes
  mode = modes[mode_name]
  if mode
    instance = live[mode]
    if instance
      instance.config[k] = v for k,v in pairs variables

register name: 'default', create: DefaultMode

return PropertyTable {
  :for_file
  :by_name
  :register
  :unregister
  :configure
  names: get: -> [name for name in pairs modes]
}
