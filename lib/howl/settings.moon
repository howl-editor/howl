serpent = require 'serpent'

import File from howl.io
import SandboxedLoader from howl.util
{:env} = howl.sys

default_dir = ->
  howl_dir = env.HOWL_DIR
  return File(howl_dir) if howl_dir
  home = env.HOME
  xdg_config_home = env.XDG_CONFIG_HOME

  -- if none of these are set, we won't be able to find config
  unless home or xdg_config_home
    error "Could not find conf directory to use ($HOME not set?)"

  home = File home
  dotdir = home\join('.howl')
  local xdg_conf_dir

  if xdg_config_home
    xdg_conf_dir = File(xdg_config_home)\join('howl')

  unless xdg_conf_dir and xdg_conf_dir.is_directory
    -- check for howl dir in default XDG_CONFIG_HOME location
    xdg_conf_dir = home\join('.config', 'howl')

  -- trying ~/.howl first
  if dotdir.is_directory
    if xdg_conf_dir and xdg_conf_dir.exists
      log.warn("Ignoring #{xdg_conf_dir} in favour of #{dotdir}")

    return dotdir

  -- else the xdg config dir, if it exists
  if xdg_conf_dir and xdg_conf_dir.is_directory
    return xdg_conf_dir

  -- no existing dir found, create a new one at ~/.howl
  dotdir

class Settings

  new: (dir = default_dir!) =>
    unless dir.exists
      if dir.parent.exists
        dir\mkdir!
      else
        return

    @dir = dir
    @sysdir = @dir / 'system'
    @sysdir\mkdir! unless @sysdir.exists

  load_user: =>
    return unless @dir
    for ext in *{ 'bc', 'moon', 'lua' }
      init = @dir\join "init.#{ext}"
      if init.exists
        loader = SandboxedLoader @dir, 'user', no_implicit_globals: true
        loader -> user_load 'init'
        break

  save_system: (name, t) =>
    file = @sysdir\join(name .. '.lua')
    options = indent: '  ', fatal: true
    file.contents = serpent.dump t, options

  load_system: (name) =>
    file = @sysdir\join(name .. '.lua')
    return nil unless file.exists
    (assert loadfile(file))!
