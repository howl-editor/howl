mode_reg =
  name: 'lua'
  shebangs: '/lua.*$'
  extensions: 'lua'
  create: bundle_load('lua_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'lua'

return {
  info:
    author: 'Copyright 2012-2013 Nils Nordman <nino at nordman.org>',
    description: 'Lua mode',
    license: 'MIT',
  :unload
}
