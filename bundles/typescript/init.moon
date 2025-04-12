-- Copyright 2025 The Howl Developers
-- License: MIT

mode_reg =
  name: 'typescript'
  extensions: { 'ts', 'tsx' }
  shebangs: {'[/ ]deno$'}
  create: -> bundle_load('typescript_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'typescript'

return {
  info:
    author: 'The Howl Developers'
    description: 'TypeScript support'
    license: 'MIT'
  :unload
}
