-- Copyright 2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, command, config, mode, io, inspection, activities from howl

{:fmt} = bundle_load 'go_fmt'

register_inspections = ->
  inspection.register
    name: 'golint'
    factory: -> { cmd: 'golint <file>', type: 'warning' }
  inspection.register
    name: 'gotoolvet'
    factory: -> { cmd: 'go tool vet <file>', type: 'error' }


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
  command.register
    name: 'go-doc',
    description: 'Display documentation obtained with gogetdoc'
    handler: ->
      buffer = app.editor.buffer
      if buffer.mode.name != 'go'
        log.error 'Buffer is not a go mode buffer'
        return
      cmd_str = string.format "gogetdoc -pos %s:#%d -modified -linelength 999",
        buffer.file,
        buffer\byte_offset(app.editor.cursor.pos) - 2
      success, pco = pcall io.Process.open_pipe, cmd_str, {
        stdin: string.format("%s\n%d\n%s", buffer.file, buffer.size, buffer.text)
      }
      if not success
        log.error pco
        return
      stdout, _ = activities.run_process {title: 'running gogetdoc'}, pco
      if #stdout ~= 0
        buf = howl.Buffer mode.by_name 'default'
        buf.text = stdout
        app.editor\show_popup howl.ui.BufferPopup buf

register_mode!
register_commands!
register_inspections!

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
  command.unregister 'go-doc'
  inspection.unregister 'golint'
  inspection.unregister 'gotoolvet'

return {
  info:
    author: 'Copyright 2016 The Howl Developers'
    description: 'Go language support'
    license: 'MIT'
  :unload
}
