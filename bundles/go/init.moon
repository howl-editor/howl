import app, command, config, mode, signal from howl
{:fmt} = bundle_load 'go_fmt'

register_mode = ->
  mode_reg =
    name: 'go'
    aliases: 'golang'
    extensions: 'go'
    create: -> bundle_load('go_mode')
    parent: 'curly_mode'
  
  mode.register mode_reg
  
register_commands = ->
  command.register
    name: 'go-fmt',
    description: 'Run go fmt on the current buffer and reload if reformatted'
    handler: ->
      fmt app.editor.buffer
      
buffer_saved = (args) ->
  fmt args.buffer
  
register_mode!
register_commands!
signal.connect 'buffer-saved', buffer_saved

config.define
  name: 'go_fmt_command'
  description: 'Command to run for go-fmt'
  default: 'gofmt -w'
  scope: 'global'

unload = ->
  mode.unregister 'go'
  command.unregister 'go-fmt'
  signal.disconnect 'buffer-saved', buffer_saved

return {
  info:
    author: 'Copyright 2016 The Howl Developers'
    description: 'Go language support'
    license: 'MIT'
  :unload
}
