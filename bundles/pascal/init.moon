-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

howl.mode.register
  name: 'pascal'
  extensions: {'pas', 'pp', 'p', 'dpk', 'dpr', 'lpr'}
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
