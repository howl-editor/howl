-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'haml'
  extensions: 'haml'

  create: -> bundle_load('haml_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'haml'

return {
  info:
    author: 'Copyright 2013-2015 The Howl Developers',
    description: 'Haml mode',
    license: 'MIT',
  :unload
}
