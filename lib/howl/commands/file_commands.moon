-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import command, mode, Buffer, Project from howl

with_vc = (f) ->
  buffer = _G.editor.buffer
  unless buffer.file
    log.error "No file associated with buffer '#{buffer}'"
    return

  project = Project.for_file buffer.file
  unless project and project.vc
    log.error "No VC found for buffer '#{buffer}'"
    return

  f project.vc, buffer, project

show_diff_buffer = (title, contents) ->
  buffer = Buffer mode.by_name 'diff'
  buffer.text = contents
  buffer.title = "* Diff: #{title} *"
  buffer.modified = false
  howl.app\add_buffer buffer

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

command.alias 'save', 'w'

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

command.register
  name: 'vc-diff-file',
  description: 'Shows a diff against the VC for the current file'
  handler: ->
    with_vc (vc, buffer) ->
      diff = vc\diff buffer.file
      if diff
        show_diff_buffer buffer.file.basename, diff
      else
        log.info "VC: No differences found for #{buffer.file.basename}"

command.register
  name: 'vc-diff',
  description: 'Shows a diff against the VC for the current project'
  handler: ->
    with_vc (vc, buffer, project) ->
      diff = vc\diff!
      if diff
        show_diff_buffer vc.root, diff
      else
        log.info "VC: No differences found for #{project.root}"
