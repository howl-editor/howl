by_extension = {}
modes = {}

for_file = (file) ->
  return by_name 'default' if not file
  ext = file.extension
  mode = by_extension[ext]
  mode or by_name 'default'
  mode.create!

by_name = (name) ->
  return modes[name].create!

register = (mode) ->
  extensions = mode.extensions
  extensions = { extensions } if type(extensions) == 'string'
  by_extension[ext] = mode for ext in *(extensions or {})
  modes[mode.name] = mode

return :for_file, :by_name, :register
