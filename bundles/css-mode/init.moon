-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

mode_reg =
  name: 'css'
  extensions: 'css'
  create: -> bundle_load('css_mode.moon')!
  config: {
    word_pattern: '[-_%w]+'
  }

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'css'

return {
  info:
    author: 'Copyright 2013 Nils Nordman <nino at nordman.org>',
    description: 'CSS mode',
    license: 'MIT',
  :unload
}
