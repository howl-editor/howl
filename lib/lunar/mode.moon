class DefaultMode
  true

by_extension = {}
modes = {}

by_name = (name) ->
  modes[name] and modes[name].create!

for_file = (file) ->
  return by_name('Default') if not file
  ext = file.extension
  mode = by_extension[ext] or modes['Default']
  error 'No mode available for "' .. file .. '"' if not mode
  mode.create!

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

register name: 'Default', create: DefaultMode

return setmetatable { :for_file, :by_name, :register, :unregister }, {
  __pairs: => (_, index) -> return next modes, index
}
