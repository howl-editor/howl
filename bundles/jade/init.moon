-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

mode_reg =
  name: 'jade'
  extensions: 'jade'
  create: -> bundle_load('jade_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'jade'

return {
  info:
    author: 'Copyright 2014 Nils Nordman <nino at nordman.org>',
    description: 'Jade mode',
    license: 'MIT',
  :unload
}
