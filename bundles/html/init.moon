mode_reg =
  name: 'html'
  extensions: { 'htm', 'html', 'shtm', 'shtml', 'xhtml' }
  create: -> bundle_load('html_mode')

howl.mode.register mode_reg
howl.lsp.register_server {
  name: 'vscode-html-language-server'
  command: 'vscode-html-language-server --stdio'
  modes: 'html'
}

unload = ->
  howl.mode.unregister 'html'
  howl.lsp.unregister_server 'vscode-html-language-server'

return {
  info:
    author: 'Copyright 2014-2015 The Howl Developers',
    description: 'HTML support',
    license: 'MIT',
  :unload
}
