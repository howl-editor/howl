-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see README.md at the top-level directory of the bundle)

mode_reg =
  name: 'mail-mode'
  extensions: {'eml', 'mbox', 'mbx'}
  create: -> bundle_load('mail_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'mail-mode'

return {
  info:
    author: 'Copyright 2015 The Howl Developers',
    description: 'Mail mode',
    license: 'MIT',
  :unload
}
