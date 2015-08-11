mode_reg =
  name: 'markdown'
  extensions: {'md', 'markdown'}
  create: -> bundle_load('markdown_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'markdown'

return {
  info:
    author: 'Copyright 2013-2015 The Howl Developers',
    description: 'Markdown support',
    license: 'MIT',
  :unload
}
