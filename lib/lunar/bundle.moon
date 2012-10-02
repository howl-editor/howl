import File from lunar.fs
import Sandbox from lunar.aux

import assert, error, loadfile, type, _G from _G

_G.bundles = {}

bundle = {}
setfenv 1, bundle

export dirs = {}

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

load_file = (file, sandbox, ...) ->
  chunk = assert loadfile file
  sandbox chunk, ...

bundle_sandbox = (dir) ->
  loaded = {}
  loading = {}
  box = Sandbox {}, no_implicit_globals: true
  box\put {
    bundle_file: (rel_path) -> dir / rel_path
    bundle_load: (rel_path, ...) ->
      error 'Cyclic dependency in ' .. dir / rel_path if loading[rel_path]
      return loaded[rel_path] if loaded[rel_path]
      loading[rel_path] = true
      path = dir / rel_path
      mod = load_file path, box, ...
      loading[rel_path] = false
      loaded[rel_path] = mod
      mod
  }
  box

export load_from_dir = (dir) ->
  error 'Not a directory: ' .. dir if not dir.is_directory
  init = find_bundle_init dir
  sandbox = bundle_sandbox dir
  bundle = load_file init, sandbox
  verify_bundle bundle, init
  _G.bundles[module_name dir.basename] = bundle

export load_by_name = (name) ->
  mod_name = module_name name

  for dir in *dirs
    for c in *dir.children
      is_candidate = c.is_directory and not c.is_hidden
      if is_candidate and module_name(c.basename) == mod_name or c.basename == name
        load_from_dir c
        return

  error 'bundle "' .. name .. '" was not found', 2

export load_all = ->
  for dir in *dirs
    for c in *dir.children
      if c.is_directory and not c.is_hidden
        load_from_dir c

return bundle
