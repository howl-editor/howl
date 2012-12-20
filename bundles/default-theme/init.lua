local theme_file = bundle_file('default_theme.moon')

howl.ui.theme.register('Default', theme_file)

return {
  info = {
    name = 'default_theme',
    author = 'Copyright 2012 Nils Nordman <nino at nordman.org>',
    description = 'The default theme',
    license = 'MIT',
  }
}
