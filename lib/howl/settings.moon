serpent = require 'serpent'

import File from howl.io
import SandboxedLoader from howl.aux

default_dir = ->
  howl_dir = os.getenv 'HOWL_DIR'
  return File(howl_dir) if howl_dir
  home = os.getenv('HOME')
  home and File(home)\join('.howl') or nil

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
