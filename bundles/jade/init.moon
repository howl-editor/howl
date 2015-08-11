-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'jade'
  extensions: 'jade'
  create: -> bundle_load('jade_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'jade'

return {
  info:
    author: 'Copyright 2014-2015 The Howl Developers',
    description: 'Jade mode',
    license: 'MIT',
  :unload
}
