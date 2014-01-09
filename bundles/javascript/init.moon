mode_reg =
  name: 'javascript'
  extensions: { 'js', 'jsfl' }
  create: -> bundle_load('javascript_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'javascript'

return {
  info:
    author: 'Copyright 2014 Nils Nordman <nino at nordman.org>',
    description: 'JavaScript support',
    license: 'MIT',
  :unload
}
