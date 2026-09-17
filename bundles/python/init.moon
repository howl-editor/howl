-- Copyright 2012-2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'python'
  extensions: { 'sc', 'py', 'pyw', 'pyx' }
  patterns: { 'wscript$', 'SConstruct$', 'SConscript$' }
  shebangs: '[/ ]python.*$'
  create: -> bundle_load('python_mode')

howl.mode.register mode_reg

howl.inspection.register {
  name: 'python-ruff',
  factory: (buffer) ->
    bundle_load('ruff_inspector') buffer
}

unload = ->
  howl.mode.unregister 'python'
  howl.inspection.unregister 'python-ruff'

return {
  info:
    author: 'Copyright 2015 The Howl Developers',
    description: 'Python bundle with Jinja2 support',
    license: 'MIT',
  :unload
}
