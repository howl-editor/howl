-- Copyright 2012-2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'python'
  extensions: { 'sc', 'py', 'pyw', 'pyx' }
  patterns: { 'wscript$', 'SConstruct$', 'SConscript$' }
  shebangs: '[/ ]python.*$'
  create: -> bundle_load('python_mode')

howl.mode.register mode_reg

howl.Project.register_environment_provider {
  name: 'python-virtualenv'
  files: { 'pyproject.toml', 'poetry.lock' }
  handler: bundle_load('virtualenv')
}

unload = ->
  howl.mode.unregister 'python'
  howl.Project.unregister_environment_provider 'python-virtualenv'

return {
  info:
    author: 'Copyright 2015 The Howl Developers',
    description: 'Python bundle',
    license: 'MIT',
  :unload
}
