import command from lunar

command.register
  name: 'open',
  description: 'Open file'
  inputs: { 'file' }
  handler: (file) -> lunar.app\open_file file

command.alias 'open', 'e'

command.register
  name: 'project-open',
  description: 'Open project file'
  inputs: { 'project_file' }
  handler: (file) -> lunar.app\open_file file

command.register
  name: 'save',
  description: 'Save file'
  inputs: {}
  handler: ->
    buffer = _G.editor.buffer
    if buffer.file
      buffer\save!
      nr_lines = #buffer.lines
      log.info ("%s: %d lines, %d bytes written")\format buffer.file.basename,
        nr_lines, #buffer

command.alias 'save', 'w'
