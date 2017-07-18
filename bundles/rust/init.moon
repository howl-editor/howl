-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'rust'
  aliases: 'rs'
  extensions: 'rs'
  create: -> bundle_load('rust_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'rust'

return {
  info:
    author: 'Alejandro Baez https://keybase.io/baez',
    description: 'Rust language support',
    license: 'MIT',
  :unload
}
