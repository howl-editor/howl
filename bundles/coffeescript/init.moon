mode_reg =
  name: 'coffeescript'
  extensions: 'coffee'
  shebangs: '/coffee$'
  create: -> bundle_load('coffeescript_mode') 'coffeescript_lexer'

howl.mode.register mode_reg

mode_reg =
  name: 'litcoffeescript'
  extensions: 'litcoffee'
  patterns: '%.coffee%.md$'
  create: -> bundle_load('coffeescript_mode') 'litcoffeescript_lexer'

howl.mode.register mode_reg

unload = ->
  howl.mode.unregister 'coffeescript'
  howl.mode.unregister 'litcoffeescript'

return {
  info:
    author: 'Copyright 2014-2015 The Howl Developers',
    description: 'Coffeescript mode',
    license: 'MIT',
  :unload
}
