-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

require_bundle 'lua'

commands = bundle_load 'howlscript_commands'

mode_reg =
  name: 'howlscript'
  aliases: 'howl'
  extensions: 'howl'
  create: -> bundle_load('howlscript_mode')!

howl.mode.register mode_reg
howl.inspection.register {
  name: 'howlscript',
  factory: ->
    bundle_load('howlscript_inspector')
}
howl.command.register cmd for cmd in *commands.commands

unload = ->
  howl.mode.unregister 'howlscript'
  howl.inspection.unregister 'howlscript'
  howl.command.unregister cmd.name for cmd in *commands.commands

return {
  info:
    author: 'Copyright 2026 The Howl Developers',
    description: 'Howlscript mode',
    license: 'MIT',
  :unload
  :commands
}
