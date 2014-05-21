-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app, command, mode, inputs, Buffer, Project from howl
import File from howl.io

with_vc = (f) ->
  buffer = app.editor.buffer
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
  buffer.can_undo = false
  app\add_buffer buffer

command.register
  name: 'open',
  description: 'Open file'
  input: 'file'
  handler: (file) -> app\open_file file

command.alias 'open', 'e'

command.register
  name: 'project-open',
  description: 'Open project file'
  handler: ->
    buffer = app.editor and app.editor.buffer
    file = buffer and (buffer.file or buffer.directory)
    if file
      project = Project.get_for_file file
      if project
        file = app.window.readline\read ':project-open ', 'project_file'
        app\open_file file if file
    else
      log.warn "No file or directory associated with the current view"

command.register
  name: 'save',
  description: 'Saves the current buffer to file'
  handler: ->
    buffer = app.editor.buffer
    return command.run 'save-as' unless buffer.file

    if buffer.modified_on_disk
      input = inputs.yes_or_no false
      prompt = "Buffer '#{buffer}' has changed on disk, save anyway? "
      unless inputs.read input, :prompt
        log.info "Not overwriting; buffer not saved"
        return

    buffer\save!
    nr_lines = #buffer.lines
    log.info ("%s: %d lines, %d bytes written")\format buffer.file.basename,
      nr_lines, #buffer

command.alias 'save', 'w'

command.register
  name: 'save-as',
  description: 'Saves the current buffer to a given file'
  input: 'file'
  handler: (file) ->
    if file.exists
      input = inputs.yes_or_no false
      unless inputs.read input, prompt: "File '#{file}' already exists, overwrite? "
        log.info "Not overwriting; buffer not saved"
        return

    buffer = app.editor.buffer
    buffer.file = file
    command.save!

command.register
  name: 'close',
  description: 'Closes the current buffer'
  handler: ->
    buffer = app.editor.buffer
    app\close_buffer buffer

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

command.register
  name: 'diff-buffer-against-saved',
  description: 'Shows a diff against the saved file for the current buffer'
  handler: ->
    buffer = app.editor.buffer
    unless buffer.file
      log.error "No file associated with buffer '#{buffer}'"
      return

    File.with_tmpfile (file) ->
      file.contents = buffer.text
      pipe = assert io.popen "diff -u #{buffer.file} #{file}"
      diff = assert pipe\read '*a'
      pipe\close!
      if diff and not diff.is_blank
        show_diff_buffer "Compared to disk: #{buffer.file.basename}", diff
      else
        log.info "No unsaved modifications found for #{buffer.file.basename}"
