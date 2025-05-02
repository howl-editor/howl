-- Copyright 2019 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

modes = {
  {
    name: 'ini'
    extensions: {'cfg', 'cnf', 'inf', 'ini'}
  }

  {
    name: 'xdg'
    extensions: { 'desktop' }
  }

  {
    name: 'systemd'
    extensions: {
      'service', 'socket', 'device', 'mount', 'automount', 'swap', 'target', 'path',
      'timer', 'slice', 'scope',
    }
  }

  {
    name: 'editorconfig'
    patterns: { '.editorconfig$' }
    extensions: { 'editorconfig' }
  }

  {
    name: 'regedit'
    extensions: { 'reg' }
  }
}

for mode_reg in *modes
  mode_reg.create = -> bundle_load('ini_mode')(mode_reg.name)
  howl.mode.register mode_reg

unload = ->
  for mode_reg in *modes
    howl.mode.unregister mode_reg.name

return {
  info:
    author: 'Copyright 2019 The Howl Developers',
    description: 'INI file modes',
    license: 'MIT',
  :unload
}
