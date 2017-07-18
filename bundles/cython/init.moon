-- Copyright 2017 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import mode from howl

register_mode = ->
  mode_reg =
    name: 'cython'
    extensions: {'pyx', 'pxd'}
    create: -> bundle_load('cython_mode')
    parent: 'python'

  mode.register mode_reg

register_mode!

unload = ->
  mode.unregister 'cython'

return {
  info:
    author: 'Copyright 2017 The Howl Developers',
    description: 'Cython mode',
    license: 'MIT',
  :unload
}
