-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'python'
  extensions: { 'sc', 'py', 'pyw', 'pyx' }
  patterns: { 'wscript$', 'SConstruct$', 'SConscript$' }
  shebangs: '[/ ]python.*$'
  create: -> bundle_load('python_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'python'

return {
  info:
    author: 'Copyright 2015 The Howl Developers',
    description: 'Python bundle',
    license: 'MIT',
  :unload
}
