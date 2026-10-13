-- Copyright 2012-2025 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'python'
  extensions: { 'sc', 'py', 'pyw', 'pyx' }
  patterns: { 'wscript$', 'SConstruct$', 'SConscript$' }
  shebangs: '[/ ]python.*$'
  create: -> bundle_load('python_mode')

lsp_servers = {
  { name: 'zuban', command: 'zuban server', modes: 'python' },
  { name: 'ty', command: 'ty server', modes: 'python' },
  { name: 'basedpyright', command: 'basedpyright-langserver --stdio', modes: 'python' },
  { name: 'pyright', command: 'pyright-langserver --stdio', modes: 'python' },
  { name: 'pylsp', command: 'pylsp', modes: 'python' },
  { name: 'jedi-language-server', command: 'jedi-language-server', modes: 'python' }
}

howl.mode.register mode_reg
howl.lsp.register_server s for s in *lsp_servers

howl.Project.register_environment_provider {
  name: 'python-virtualenv'
  files: { 'pyproject.toml', 'poetry.lock' }
  handler: bundle_load('virtualenv')
}

unload = ->
  howl.mode.unregister 'python'
  howl.lsp.unregister_server s.name for s in *lsp_servers
  howl.Project.unregister_environment_provider 'python-virtualenv'

return {
  info:
    author: 'Copyright 2015 The Howl Developers',
    description: 'Python bundle',
    license: 'MIT',
  :unload
}
