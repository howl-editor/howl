mode_reg =
  name: 'dart'
  extensions: { 'dart' }
  create: -> bundle_load('dart_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg
howl.lsp.register_server name: 'dart', command: 'dart language-server', modes: 'dart'

unload = ->
  howl.mode.unregister 'dart'
  howl.lsp.unregister_server 'dart'

return {
  info:
    author: 'Copyright 2017 The Howl Developers',
    description: 'Dart support',
    license: 'MIT',
  :unload
}
