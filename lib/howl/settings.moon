serpent = require 'serpent'

import File from howl.io
import SandboxedLoader from howl.aux

default_dir = ->
  howl_dir = os.getenv 'HOWL_DIR'
  return File(howl_dir) if howl_dir
  home = os.getenv('HOME')
  xdg_config_home = os.getenv('XDG_CONFIG_HOME')
  -- if none of this are set, we wwon't be able to find config
  return nil unless home or xdg_config_home
  -- trying ~/.howl first
  dotdir = nil
  if home
    dotdir = File(home)\join('.howl')
    return dotdir if dotdir.is_directory
  -- trying xdg-complaint ~/.config/howl
  xdg_conf_dir = nil
  if xdg_config_home
    xdg_conf_dir = File(xdg_config_home)\join('howl')
  elseif home
    xdg_conf_dir = File(home)\join('.config')\join('howl')
  if xdg_conf_dir and xdg_conf_dir.is_directory
    return xdg_conf_dir
  -- if none of these exists falling back to ~/.howl
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
