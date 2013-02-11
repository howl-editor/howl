mode_reg =
  name: 'moonscript'
  extensions: 'moon'
  create: -> bundle_load('moonscript_mode.moon')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'moonscript'

return {
  info:
    name: 'moonscript_mode',
    author: 'Copyright 2012-2013 Nils Nordman <nino at nordman.org>',
    description: 'Moonscript mode',
    license: 'MIT',
  :unload
}
