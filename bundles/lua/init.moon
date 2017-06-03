{:config} = howl

mode_reg =
  name: 'lua'
  shebangs: {'/lua.*$', '/env lua.*$'}
  extensions: {'lua', 'luacheckrc'}
  create: bundle_load('lua_mode')

provide_module 'luacheck'

howl.mode.register mode_reg
howl.inspection.register {
  name: 'luacheck',
  factory: ->
    bundle_load('luacheck_inspector')
}

config.define {
  name: 'luacheck_config_path',
  description: 'Path to luacheck configuration file',
  default: '.luacheckrc'
}

unload = ->
  howl.mode.unregister 'lua'
  howl.inspection.unregister 'luacheck'

return {
  info:
    author: 'Copyright 2012-2017 The Howl Developers',
    description: 'Lua mode',
    license: 'MIT',
  :unload
}
