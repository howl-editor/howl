-- Copyright 2020 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'zig'
  aliases: 'zig'
  extensions: 'zig'
  create: -> bundle_load('zig_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg
howl.lsp.register_server name: 'zls', command: 'zls', modes: 'zig'

unload = ->
  howl.mode.unregister 'zig'
  howl.lsp.unregister_server 'zls'

return {
  info:
    author: 'Crystal Jelly',
    description: 'Zig language support',
    license: 'MIT',
  :unload
}
