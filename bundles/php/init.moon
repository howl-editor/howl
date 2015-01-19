-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

mode_reg =
  name: 'php'
  extensions: { 'php', 'php3', 'php4', 'phtml' }
  shebangs: '[/ ]php.*$'
  create: -> bundle_load('php_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'php'

return {
  info:
    author: 'Copyright 2014 Nils Nordman <nino at nordman.org>',
    description: 'PHP support',
    license: 'MIT',
  :unload
}
