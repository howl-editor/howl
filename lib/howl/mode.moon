import config, signal from howl
import PropertyTable from howl.aux

by_extension = {}
by_pattern = {}
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

  target = m.create m.name
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
  return by_name('default') unless file
  def = file.extension and by_extension[file.extension\lower!]
  unless def
    for pattern, mode in pairs by_pattern
      if tostring(file)\match pattern
        def = mode
        break

  def or= modes['default']
  instance = def and instance_for_mode def
  error 'No mode available for "' .. file .. '"' if not instance
  instance

register = (mode = {}) ->
  error 'Missing field `name` for mode', 2 if not mode.name
  error 'Missing field `create` for mode', 2 if not mode.create

  extensions = mode.extensions or {}
  extensions = { extensions } if type(extensions) == 'string'
  by_extension[ext] = mode for ext in *extensions

  patterns = mode.patterns or {}
  patterns = { patterns } if type(patterns) == 'string'
  by_pattern[pattern] = mode for pattern in *patterns

  modes[mode.name] = mode
  signal.emit 'mode-registered', name: mode.name

unregister = (name) ->
  mode = modes[name]
  if mode
    modes[name] = nil
    exts = [ext for ext, m in pairs by_extension when m == mode]
    by_extension[ext] = nil for ext in *exts

    patterns = [pattern for pattern, m in pairs by_pattern when m == mode]
    by_pattern[pattern] = nil for pattern in *patterns

    live[mode] = nil
    signal.emit 'mode-unregistered', :name

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

signal.register 'mode-registered',
  description: 'Signaled right after a mode was registered',
  parameters:
    name: 'The name of the mode'

signal.register 'mode-unregistered',
  description: 'Signaled right after a mode was unregistered',
  parameters:
    name: 'The name of the mode'

register name: 'default', create: howl.modes.DefaultMode

return PropertyTable {
  :for_file
  :by_name
  :register
  :unregister
  :configure
  names: get: -> [name for name in pairs modes]
}
