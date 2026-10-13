mode_reg =
  name: 'c'
  aliases: { 'c', 'c++' }
  extensions: { 'c', 'cc', 'cpp', 'cxx', 'c++', 'h', 'hh', 'hpp', 'hxx', 'h++' }
  create: -> bundle_load('c_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg
howl.lsp.register_server name: 'clangd', command: 'clangd', modes: 'c'

unload = ->
  howl.mode.unregister 'c'
  howl.lsp.unregister_server 'clangd'

return {
  info:
    author: 'Copyright 2014-2015 The Howl Developers',
    description: 'C language support',
    license: 'MIT',
  :unload
}
