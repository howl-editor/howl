import command from vilu

command.register
  name: 'q',
  description: 'Quits the application'
  inputs: {}
  handler: -> vilu.app\quit!

command.alias 'q', 'quit'
