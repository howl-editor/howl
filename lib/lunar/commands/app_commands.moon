import command from lunar

command.register
  name: 'q',
  description: 'Quits the application'
  inputs: {}
  handler: -> lunar.app\quit!

command.alias 'q', 'quit'

command.register
  name: 'switch_buffer',
  description: 'Switches to another buffer'
  inputs: { 'buffer' }
  handler: (buffer) ->
    _G.editor.buffer = buffer
