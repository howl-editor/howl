-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

mode_reg =
  name: 'haml'
  extensions: 'haml'

  create: -> bundle_load('haml_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'haml'

return {
  info:
    author: 'Copyright 2013 Nils Nordman <nino at nordman.org>',
    description: 'Haml mode',
    license: 'MIT',
  :unload
}
