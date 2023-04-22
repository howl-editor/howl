-- Copyright 2012-2020 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.mode.register
  name: 'haskell'
  extensions: 'hs'
  create: -> bundle_load('haskell/haskell_mode')

howl.mode.register
  name: 'cabal'
  extensions: 'cabal'
  patterns: { 'cabal.config$', 'cabal.project$', 'cabal.project.local$', 'cabal.project.freeze$' }
  create: -> bundle_load('cabal/cabal_mode')

unload = ->
  howl.mode.unregister 'haskell'
  howl.mode.unregister 'cabal'

return {
  info:
    author: 'Copyright 2020 The Howl Developers',
    description: 'Haskell bundle',
    license: 'MIT',
  :unload
}
