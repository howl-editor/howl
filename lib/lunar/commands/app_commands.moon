import command from lunar

command.register
  name: 'q',
  description: 'Quits the application'
  inputs: {}
  handler: -> lunar.app\quit!

command.alias 'q', 'quit'
