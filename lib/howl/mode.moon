import PropertyTable from howl.aux

class DefaultMode
  true

by_extension = {}
modes = {}
live = setmetatable {}, __mode: 'k'

instance_for_mode = (m) ->
  return live[m] if live[m]
  instance = m.create!
  rawset instance, 'name', m.name
  live[m] = instance
  instance

by_name = (name) ->
  modes[name] and instance_for_mode modes[name]

for_file = (file) ->
  return by_name('Default') if not file
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

register name: 'default', create: DefaultMode

return PropertyTable {
  :for_file
  :by_name
  :register
  :unregister
  names: get: -> [name for name in pairs modes]
}
