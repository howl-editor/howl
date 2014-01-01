-- Copyright 2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

mode_reg =
  name: 'ruby'
  extensions: { 'rb', 'Rakefile', 'rake', 'rb', 'rbw', 'gemspec'  }
  patterns: { 'Rakefile$', 'Gemfile$', 'Guardfile$'  }
  shebangs: '[/ ]ruby.*$'
  create: -> bundle_load('ruby_mode')!

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'ruby'

return {
  info:
    author: 'Copyright 2013 Nils Nordman <nino at nordman.org>',
    description: 'Ruby bundle',
    license: 'MIT',
  :unload
}
