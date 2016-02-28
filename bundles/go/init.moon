mode_reg =
  name: 'go'
  aliases: 'golang'
  extensions: 'go'
  create: -> bundle_load('go_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg

unload = -> mode.unregister 'go'

return {
  info:
    author: 'Copyright 2016 The Howl Developers'
    description: 'Go language support'
    license: 'MIT'
  :unload
}
