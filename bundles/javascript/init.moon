mode_reg =
  name: 'javascript'
  extensions: { 'js', 'jsfl', 'jsm', 'es' }
  shebangs: {'[/ ]node$', '[/ ]nodejs$', '[/ ]gjs$'}
  create: -> bundle_load('javascript_mode')
  parent: 'curly_mode'

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'javascript'

return {
  info:
    author: 'Copyright 2014-2015 The Howl Developers',
    description: 'JavaScript support',
    license: 'MIT',
  :unload
}
