-- Copyright 2025 The Howl Developers
-- License: MIT

mode_reg =
  name: 'typescript'
  extensions: { 'ts', 'tsx' }
  shebangs: {'[/ ]deno$'}
  create: -> bundle_load('typescript_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg
-- serves JavaScript as well, and is registered once for both
howl.lsp.register_server {
  name: 'typescript-language-server'
  command: 'typescript-language-server --stdio'
  modes: { 'typescript', 'javascript' }
}

unload = ->
  howl.mode.unregister 'typescript'
  howl.lsp.unregister_server 'typescript-language-server'

return {
  info:
    author: 'The Howl Developers'
    description: 'TypeScript support'
    license: 'MIT'
  :unload
}
