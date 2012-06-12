import File from vilu.fs
import Sandbox from vilu.aux

export bundles = {}

find_bundle_init = (dir) ->
  for f in *{'init.moon', 'init.lua'}
    path = dir / f
    return path if path.exists
  error 'Failed to find bundle init file in "' .. dir .. '"'

module_name = (name) ->
  name\lower!\gsub '[%s%p]+', '_'

verify_bundle = (bundle, init) ->
  if type(bundle) != 'table'
    error 'Incorrect bundle: no table returned from ' .. init

  info = bundle.info
  if type(info) != 'table'
    error 'Incorrect bundle: info missing in ' .. init

  for field in *{ 'name', 'description', 'license', 'author' }
    error init.path .. ': missing field "' .. field .. '"' if not info[field]

load = (dir) ->
  error 'Not a directory: ' .. dir if not dir.is_directory
  init = find_bundle_init dir
  chunk = assert loadfile init
  env = bundle_file: (rel_path) -> dir / rel_path
  box = Sandbox env, no_implicit_globals: true
  bundle = box chunk
  verify_bundle bundle, init
  bundles[module_name dir.basename] = bundle

init = (dir) ->
  for c in *dir.children
    if c.is_directory and not c.is_hidden
      load c

return :init, :load
