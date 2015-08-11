mode_reg =
  name: 'html'
  extensions: { 'htm', 'html', 'shtm', 'shtml', 'xhtml' }
  create: -> bundle_load('html_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'html'

return {
  info:
    author: 'Copyright 2014-2015 The Howl Developers',
    description: 'HTML support',
    license: 'MIT',
  :unload
}
