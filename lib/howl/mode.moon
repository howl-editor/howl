import config, signal from howl
import PropertyTable from howl.aux

by_extension = {}
by_pattern = {}
by_shebang = {}
modes = {}
live = setmetatable {}, __mode: 'k'
mode_variables = {}

local by_name

instance_for_mode = (m) ->
  return live[m] if live[m]

  error "Unknown mode specified as parent: '#{m.parent}'", 3 if m.parent and not modes[m.parent]
  parent = if m.name != 'default' then by_name m.parent or 'default'
  target = m.create m.name

  mode_config = config.local_proxy!

  if target.default_config
    mode_config[k] = v for k,v in pairs target.default_config

  mode_vars = mode_variables[m.name]
  if mode_vars
    mode_config[k] = v for k,v in pairs mode_vars

  mode_config.chain_to parent.config if parent

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

get_shebang = (file) ->
  return nil unless file.readable
  line = file\read!
  line and line\match '^#!%s*(.+)$'

for_file = (file) ->
  return by_name('default') unless file
  def = file.extension and by_extension[file.extension\lower!]

  pattern_match = (value, patterns) ->
    return nil unless value
    for pattern, mode in pairs patterns
      return mode if value\umatch pattern

  def or= pattern_match tostring(file), by_pattern
  def or= pattern_match get_shebang(file), by_shebang
  def or= modes['default']
  instance = def and instance_for_mode def
  error 'No mode available for "' .. file .. '"' if not instance
  instance

register = (mode = {}) ->
  error 'Missing field `name` for mode', 2 if not mode.name
  error 'Missing field `create` for mode', 2 if not mode.create

  multi_value = (v = {}) -> type(v) == 'string' and { v } or v

  by_extension[ext] = mode for ext in *multi_value mode.extensions
  by_pattern[pattern] = mode for pattern in *multi_value mode.patterns
  by_shebang[shebang] = mode for shebang in *multi_value mode.shebangs

  modes[mode.name] = mode
  modes[alias] = mode for alias in *multi_value mode.aliases

  signal.emit 'mode-registered', name: mode.name

unregister = (name) ->
  mode = modes[name]
  if mode
    remove_from = (table, mode) ->
      keys = [k for k, m in pairs table when m == mode]
      table[k] = nil for k in *keys

    remove_from modes, mode
    remove_from by_extension, mode
    remove_from by_pattern, mode
    remove_from by_shebang, mode

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
