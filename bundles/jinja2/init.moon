-- Copyright 2025 The Howl Developers
-- License: MIT (see LICENSE file)

mode_reg =
  name: 'jinja2'
  extensions: { 'j2', 'jinja', 'jinja2' }
  create: -> bundle_load('jinja2_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'jinja2'

return {
  info:
    author: 'Copyright 2025 The Howl Developers',
    description: 'Jinja2 template support',
    license: 'MIT',
  :unload
}
