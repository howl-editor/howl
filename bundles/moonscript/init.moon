mode_reg =
  name: 'moonscript'
  extensions: 'moon'
  shebangs: '/moon$'
  create: -> bundle_load('moonscript_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'moonscript'

return {
  info:
    author: 'Copyright 2012-2013 Nils Nordman <nino at nordman.org>',
    description: 'Moonscript mode',
    license: 'MIT',
  :unload
}
