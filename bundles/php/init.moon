-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

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
    author: 'Copyright 2014-2015 The Howl Developers',
    description: 'PHP support',
    license: 'MIT',
  :unload
}
