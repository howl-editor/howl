-- Copyright 2013-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

mode_reg =
  name: 'ruby'
  extensions: {
    'rb',
    'rake',
    'rb',
    'rbw',
    'gemspec',
    'builder',
    'thor',
    'jbuilder',
    'podspec',
    'rabl'
  }
  patterns: {
    'Rakefile$', 'Gemfile$', 'Guardfile$', 'Capfile$',
    'Cheffile$', 'Thorfile$', 'Podfile$', 'config.ru$', 'Vagrantfile$'
  }
  shebangs: '[/ ]ruby.*$'
  create: -> bundle_load('ruby_mode')

lsp_servers = {
  { name: 'ruby-lsp', command: 'ruby-lsp', modes: 'ruby' },
  { name: 'solargraph', command: 'solargraph stdio', modes: 'ruby' }
}

howl.mode.register mode_reg
howl.lsp.register_server s for s in *lsp_servers
howl.inspection.register {
  name: 'ruby',
  factory: (buffer) ->
    bundle_load('ruby_inspector') buffer
}

unload = ->
  howl.mode.unregister 'ruby'
  howl.lsp.unregister_server s.name for s in *lsp_servers
  howl.inspection.unregister 'ruby'

return {
  info:
    author: 'Copyright 2013-2015 The Howl Developers',
    description: 'Ruby bundle',
    license: 'MIT',
  :unload

  util: bundle_load('util')
}
