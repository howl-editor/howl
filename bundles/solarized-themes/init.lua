local light = bundle_file('light.moon')

howl.ui.theme.register('Solarized Light', light)

local unload = function()
  howl.ui.theme.unregister 'Solarized Light'
end

return {
  info = {
    author = 'Solarized themes adapted by Nordman <nino at nordman.org>',
    description = [[
      The Solarized themes designed by Ethan Schoonover.

      Light theme, adapted for the Howl editor by Nils Nordman.
    ]],
    license = 'MIT',
  },
  unload = unload
}
