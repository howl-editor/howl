-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md)

mode_reg =
  name: 'css'
  aliases: 'scss'
  extensions: {'css', 'scss'}
  create: -> bundle_load('css_mode')!
  parent: 'curly_mode'

howl.mode.register mode_reg
howl.lsp.register_server {
  name: 'vscode-css-language-server'
  command: 'vscode-css-language-server --stdio'
  modes: 'css'
}

unload = ->
  howl.mode.unregister 'css'
  howl.lsp.unregister_server 'vscode-css-language-server'

return {
  info:
    author: 'Copyright 2013-2015 The Howl Developers',
    description: 'CSS mode',
    license: 'MIT',
  :unload
}
