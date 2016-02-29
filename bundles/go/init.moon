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
      buffer = app.editor.buffer
      if buffer.mode.name != 'go'
        log.error 'Buffer is not a go mode buffer'
        return
      fmt buffer
      
register_mode!
register_commands!

with config
  .define
    name: 'go_fmt_on_save'
    description: 'Whether to run gofmt when go files are saved'
    default: true
    type_of: 'boolean'

  .define
    name: 'go_fmt_command'
    description: 'Command to run for go-fmt'
    default: 'gofmt'
    scope: 'global'

  .define
    name: 'go_complete'
    description: 'Whether to use gocode completions in go mode'
    default: true
    type_of: 'boolean'

unload = ->
  mode.unregister 'go'
  command.unregister 'go-fmt'

return {
  info:
    author: 'Copyright 2016 The Howl Developers'
    description: 'Go language support'
    license: 'MIT'
  :unload
}
