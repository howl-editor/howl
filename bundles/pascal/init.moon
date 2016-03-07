howl.mode.register
  name: 'pascal'
  extensions: {'pas', 'pp', 'p', 'dpk', 'dpr'}
  aliases: {'pas', 'pp', 'fpc', 'delphi'}
  create: -> bundle_load 'pascal_mode'

unload = -> howl.mode.unregister 'pascal'

{
  info:
    author: 'The Howl Developers'
    description: 'A Pascal bundle'
    license: 'MIT'
  :unload
}
