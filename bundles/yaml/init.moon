-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'yaml'
  extensions: { 'yml', 'yaml' }
  create: -> bundle_load('yaml_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'yaml'

return {
  info:
    author: 'Copyright 2013-2015 The Howl Developers',
    description: 'YAML mode',
    license: 'MIT',
  :unload
}
