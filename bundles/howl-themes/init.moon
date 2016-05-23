-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

theme = howl.ui.theme

themes = {
  'Steinom': bundle_file('steinom/steinom.moon')
  'Tomorrow Night Blue': bundle_file('tomorrow_night_blue/tm_night_blue.moon')
  'Solarized Light': bundle_file('solarized_light/solarized_light.moon')
  'Monokai': bundle_file('monokai/monokai.moon')
  'Blueberry Jam': bundle_file('blueberry_jam/blueberry_jam.moon')
}

for name, file in pairs themes
  theme.register(name, file)

unload = ->
  for name in pairs themes
    theme.unregister name

{
  info: {
    author: 'The Howl Developers',
    description: 'Bundled themes for the Howl editor',
    license: 'Mixed (see README.md)',
  },
  unload: unload
}
