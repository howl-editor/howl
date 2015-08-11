mode_reg =
  name: 'gherkin'
  aliases: 'cucumber'
  extensions: 'feature'
  create: -> bundle_load('cucumber_mode')

howl.mode.register mode_reg

unload = -> howl.mode.unregister 'gherkin'

return {
  info:
    author: 'Copyright 2013-2015 The Howl Developers',
    description: 'Cucumber support',
    license: 'MIT',
  :unload
}
