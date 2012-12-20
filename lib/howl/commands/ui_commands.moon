import command from howl

command.register
  name: 'toggle-fullscreen',
  description: 'Toggles fullscreen for the current window'
  inputs: { }
  handler: -> _G.window\toggle_fullscreen!
