mode_reg =
  name: 'lua'
  shebangs: '/lua.*$'
  extensions: 'lua'
  create: bundle_load('lua_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'lua'

return {
  info:
    author: 'Copyright 2012-2014-2015 The Howl Developers',
    description: 'Lua mode',
    license: 'MIT',
  :unload
}
