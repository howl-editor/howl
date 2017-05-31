-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import signal from howl
import File from howl.io
import SandboxedLoader, safecall from howl.util

_G = _G
import error, log, type, callable, table, pairs, tostring, typeof, pcall from _G

_G.bundles = {}

bundle = {}
setfenv 1, bundle

export dirs = {}
provided = {}

provided_loader = (name) ->
  base = name\match('^([^.]+)')
  lookup = provided[base]
  if lookup
    load_path = "#{lookup.prefix or ''}#{name}"
    lookup.loader ->
      status, ret = pcall bundle_load, load_path
      if status
        table.insert lookup.loaded, name
        return -> ret
      else
        nil

table.insert(_G.package.loaders, 1, provided_loader)

module_name = (name) ->
  (name\lower!\gsub '[%s%p]+', '_')

available_bundles = ->
  avail = {}

  for dir in *dirs
    continue if not dir.is_directory
    for c in *dir.children
      if c.is_directory and not c.is_hidden
        b_name = module_name(c.basename)
        if avail[b_name]
          error "Conflicting bundles: '#{c}' <-> '#{avail[b_name]}'"
        avail[b_name] = c

  avail

unloaded = ->
  l = [name for name in pairs available_bundles! when not _G.bundles[name]]
  table.sort l
  l

verify_bundle = (b, dir) ->
  if type(b) != 'table'
    error "Incorrect bundle: no table returned from #{dir}"

  info = b.info
  if type(info) != 'table'
    error "Incorrect bundle: info missing for #{dir}"

  for field in *{ 'description', 'license', 'author' }
    error "Incorrect bundle: missing info field '#{field}' for #{dir}" if not info[field]

  error "Missing bundle function 'unload' in #{dir}" unless callable b.unload

export load_from_dir = (dir) ->
  error "Not a directory: #{dir}", 2 if not dir or typeof(dir) != 'File' or not dir.is_directory
  mod_name = module_name dir.basename
  error "Bundle '#{mod_name}' already loaded", 2 if _G.bundles[mod_name]

  loader = SandboxedLoader dir, 'bundle', no_implicit_globals: true
  loader\put provide_module: (name, prefix) ->
    existing = provided[name]
    if existing
      error "Module 'name' provided both by '#{existing.bundle}' and '#{mod_name}'", 2

    provided[name] = {
      :prefix,
      bundle: mod_name,
      :loader,
      loaded: {}
    }

  bundle = loader -> bundle_load 'init'
  verify_bundle bundle, dir
  _G.bundles[mod_name] = bundle
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
    safecall "Failed to load bundle in #{dir}: #{err}", load_from_dir, dir

export unload = (name) ->
  mod_name = module_name name
  def = _G.bundles[mod_name or '']
  error "Bundle with name '#{name}' not found" unless def
  def.unload!
  _G.bundles[mod_name] = nil

  for provided_name, lookup in pairs provided
    if lookup.bundle == mod_name
      for loaded_name in *lookup.loaded
        _G.package.loaded[loaded_name] = nil

      provided[provided_name] = nil

  signal.emit 'bundle-unloaded', bundle: mod_name

export from_file = (file) ->
  for bundle_dir in *dirs
    if file\is_below bundle_dir
      rel_path = file\relative_to_parent bundle_dir
      name = rel_path\match("([^#{File.separator}]+)#{File.separator}")
      return module_name(name) if name

  nil

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
