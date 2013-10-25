-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

import signal from howl
import File from howl.fs
import Sandbox from howl.aux

_G = _G
import assert, error, loadfile, type, callable, table, tostring, pairs, typeof, pcall from _G

_G.bundles = {}

bundle = {}
setfenv 1, bundle

export dirs = {}

find_bundle_file = (dir, base) ->
  for ext in *{'bc', 'lua', 'moon'}
    path = dir\join "#{base}.#{ext}"
    return path if path.exists

  error "Failed to find bundle file #{base} in '#{dir}'"

module_name = (name) ->
  name\lower!\gsub '[%s%p]+', '_'

available_bundles = ->
  avail = {}

  for dir in *dirs
    for c in *dir.children
      if c.is_directory and not c.is_hidden
        avail[module_name c.basename] = c

  avail

unloaded = ->
  l = [name for name in pairs available_bundles! when not _G.bundles[name]]
  table.sort l
  l

verify_bundle = (bundle, init) ->
  if type(bundle) != 'table'
    error 'Incorrect bundle: no table returned from ' .. init

  info = bundle.info
  if type(info) != 'table'
    error 'Incorrect bundle: info missing in ' .. init

  for field in *{ 'description', 'license', 'author' }
    error init.path .. ': missing info field "' .. field .. '"' if not info[field]

  error "Missing bundle function 'unload' in #{init}" unless callable bundle.unload

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
      path = find_bundle_file dir, rel_path unless path.exists
      mod = load_file path, box, ...
      loading[rel_path] = false
      loaded[rel_path] = mod
      mod
  }
  box

export load_from_dir = (dir) ->
  error "Not a directory: #{dir}", 2 if not dir or typeof(dir) != 'File' or not dir.is_directory
  mod_name = module_name dir.basename
  error "Bundle '#{mod_name}' already loaded", 2 if _G.bundles[mod_name]

  init = find_bundle_file dir, 'init'
  sandbox = bundle_sandbox dir
  bundle = load_file init, sandbox
  verify_bundle bundle, init
  _G.bundles[module_name dir.basename] = bundle
  signal.emit 'bundle-loaded', bundle: mod_name

export load_by_name = (name) ->
  mod_name = module_name name
  dir = available_bundles![mod_name]
  if dir
    load_from_dir dir
  else
    error 'Bundle "' .. name .. '" was not found', 2

export load_all = ->
  for _, dir in pairs available_bundles!
    status = pcall find_bundle_file, dir, 'init'
    load_from_dir dir if status

export unload = (name) ->
  mod_name = module_name name
  def = _G.bundles[mod_name or '']
  error "Bundle with name '#{name}' not found" unless def
  def.unload!
  _G.bundles[mod_name] = nil
  signal.emit 'bundle-unloaded', bundle: mod_name

signal.register 'bundle-loaded',
  description: 'Signaled right after a bundle was loaded',
  parameters:
    bundle: 'The name of the bundle'

signal.register 'bundle-unloaded',
  description: 'Signaled right after a bundle was unloaded',
  parameters:
    bundle: 'The name of the bundle'

return _G.setmetatable bundle,
  __index: (t, k) -> k == 'unloaded' and unloaded! or nil
