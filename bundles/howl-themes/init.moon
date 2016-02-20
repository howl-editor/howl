 --Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

steinom = bundle_file('steinom/steinom.moon')

howl.ui.theme.register('Steinom', steinom)

unload = ->
  howl.ui.theme.unregister 'Steinom'

{
  info: {
    author: 'The Howl Developers',
    description: 'Core themes for the Howl editor',
    license: 'Mixed (see README.md)',
  },
  unload: unload
}
