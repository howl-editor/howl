local monokai = bundle_file('monokai.moon')

howl.ui.theme.register('Monokai', monokai)

local unload = function()
  howl.ui.theme.unregister 'Monokai'
end

return {
  info = {
    author = 'Monokai themes adapted by Barnaby <barnaby at pickle.me.uk>',
    description = [[
      The Monokai themes original designed for Textmate.

      Adapted for the Howl editor by Barnaby Gray.
    ]],
    license = 'MIT',
  },
  unload = unload
}
