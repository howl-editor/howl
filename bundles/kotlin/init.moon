howl.mode.register
  name: 'kotlin'
  extensions: {'kt', 'kts'}
  aliases: {'kt', 'kts'}
  create: -> bundle_load 'kotlin_mode'
  parent: 'curly_mode'

unload = -> howl.mode.unregister 'kotlin'

{
  info:
    author: 'The Howl Developers'
    description: 'A Kotlin bundle'
    license: 'MIT'
  :unload
}
