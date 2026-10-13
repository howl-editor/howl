-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'php'
  extensions: { 'php', 'php3', 'php4', 'phtml' }
  shebangs: '[/ ]php.*$'
  create: -> bundle_load('php_mode')
  parent: 'curly_mode'

lsp_servers = {
  { name: 'intelephense', command: 'intelephense --stdio', modes: 'php' },
  { name: 'phpactor', command: 'phpactor language-server', modes: 'php' }
}

howl.mode.register mode_reg
howl.lsp.register_server s for s in *lsp_servers

unload = ->
  howl.mode.unregister 'php'
  howl.lsp.unregister_server s.name for s in *lsp_servers

return {
  info:
    author: 'Copyright 2014-2015 The Howl Developers',
    description: 'PHP support',
    license: 'MIT',
  :unload
}
