local night_blue = bundle_file('tm_night_blue.moon')

howl.ui.theme.register('Tomorrow Night Blue', night_blue)

local unload = function()
  howl.ui.theme.unregister 'Tomorrow Night Blue'
end

return {
  info = {
    author = 'Tomorrow themes adapted by Nordman <nino at nordman.org>',
    description = [[
      The Tomorrow themes designed by Chris Kempson.

      Adapted for the howl editor by Nils Nordman.
    ]],
    license = 'MIT',
  },
  unload = unload
}
