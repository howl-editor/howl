-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import command from howl

command.register
  name: 'open',
  description: 'Open file'
  inputs: { '*file' }
  handler: (file) -> howl.app\open_file file

command.alias 'open', 'e'

command.register
  name: 'project-open',
  description: 'Open project file'
  inputs: { '*project_file' }
  handler: (file) -> howl.app\open_file file

command.register
  name: 'save',
  description: 'Saves the current buffer to file'
  inputs: {}
  handler: ->
    buffer = _G.editor.buffer
    return command.run 'save-as' unless buffer.file

    buffer\save!
    nr_lines = #buffer.lines
    log.info ("%s: %d lines, %d bytes written")\format buffer.file.basename,
      nr_lines, #buffer

command.register
  name: 'save-as',
  description: 'Saves the current buffer to a given file'
  inputs: { '*file' }
  handler: (file) ->
    buffer = _G.editor.buffer
    buffer.file = file
    command.save!

command.register
  name: 'close',
  description: 'Closes the current buffer'
  inputs: {}
  handler: ->
    buffer = _G.editor.buffer
    howl.app\close_buffer buffer

command.alias 'save', 'w'
