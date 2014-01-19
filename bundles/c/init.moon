mode_reg =
  name: 'c'
  aliases: { 'c', 'c++' }
  extensions: { 'c', 'cc', 'cpp', 'cxx', 'c++', 'h', 'hh', 'hpp', 'hxx', 'h++' }
  create: -> bundle_load('c_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'c'

return {
  info:
    author: 'Copyright 2014 Nils Nordman <nino at nordman.org>',
    description: 'C language support',
    license: 'MIT',
  :unload
}
