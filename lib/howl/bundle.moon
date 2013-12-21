-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import signal from howl
import File from howl.fs
import SandboxedLoader from howl.aux

_G = _G
import assert, error, loadfile, log, type, callable, table, tostring, pairs, typeof, pcall from _G

_G.bundles = {}

bundle = {}
setfenv 1, bundle

export dirs = {}

module_name = (name) ->
  (name\lower!\gsub '[%s%p]+', '_')

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

verify_bundle = (bundle, dir) ->
  if type(bundle) != 'table'
    error "Incorrect bundle: no table returned from #{dir}"

  info = bundle.info
  if type(info) != 'table'
    error "Incorrect bundle: info missing for #{dir}"

  for field in *{ 'description', 'license', 'author' }
    error "Incorrect bundle: missing info field '#{field}' for #{dir}" if not info[field]

  error "Missing bundle function 'unload' in #{dir}" unless callable bundle.unload

export load_from_dir = (dir) ->
  error "Not a directory: #{dir}", 2 if not dir or typeof(dir) != 'File' or not dir.is_directory
  mod_name = module_name dir.basename
  error "Bundle '#{mod_name}' already loaded", 2 if _G.bundles[mod_name]

  loader = SandboxedLoader dir, 'bundle', no_implicit_globals: true
  bundle = loader -> bundle_load 'init'
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
    status, err = pcall load_from_dir, dir
    log.error "Failed to load bundle in #{dir}: #{err}" if not status

export unload = (name) ->
  mod_name = module_name name
  def = _G.bundles[mod_name or '']
  error "Bundle with name '#{name}' not found" unless def
  def.unload!
  _G.bundles[mod_name] = nil
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
