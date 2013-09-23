-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

mode_reg =
  name: 'yaml'
  extensions: { 'yml', 'yaml' }

  config:
      use_tabs: false

  create: -> bundle_load('yaml_mode.moon')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'yaml'

return {
  info:
    author: 'Copyright 2013 Nils Nordman <nino at nordman.org>',
    description: 'YAML mode',
    license: 'MIT',
  :unload
}
