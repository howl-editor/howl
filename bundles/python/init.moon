-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import config from howl

mode_reg =
  name: 'python'
  extensions: { 'sc', 'py', 'pyw', 'pyx' }
  patterns: { 'wscript$', 'SConstruct$', 'SConscript$' }
  shebangs: '[/ ]python.*$'
  create: -> bundle_load('python_mode')

howl.mode.register mode_reg

howl.inspection.register {
  name: 'mypy',
  factory: -> bundle_load('mypy_inspector')
}

config.define {
  name: 'mypy_path'
  description: 'Path to the mypy executable script'
  default: 'mypy'
}

config.define {
  name: 'mypy_config_path',
  description: 'Path to the mypy configuration file',
  default: 'mypy.ini'
}

unload = ->
  howl.mode.unregister 'python'
  howl.inspection.unregister 'mypy'

return {
  info:
    author: 'Copyright 2015 The Howl Developers',
    description: 'Python bundle',
    license: 'MIT',
  :unload
}
