-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, command, mode, inputs, interact, Buffer, Project from howl
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

auto_mkdir = (directory) ->
  return true if directory.exists

  if interact.yes_or_no prompt: "Directory #{directory} doesn't exist, create? "
    directory\mkdir_p!
    return true
  return false

command.register
  name: 'open',
  description: 'Open file'
  interactive: true
  handler: ->
    file = interact.select_file allow_new: true
    app\open_file file if file

command.alias 'open', 'e'

command.register
  name: 'project-open',
  description: 'Open project file'
  interactive: true
  handler: ->
    buffer = app.editor and app.editor.buffer
    file = buffer and (buffer.file or buffer.directory)
    if file
      project = Project.get_for_file file
      if project
        file = interact.select_file_in_project :project
        app\open_file file if file
    else
      log.warn "No file or directory associated with the current view"

command.register
  name: 'save',
  description: 'Saves the current buffer to file'
  evade_history: true
  handler: ->
    buffer = app.editor.buffer
    if not buffer.file
      app.window.command_line\run_after_finish ->
        command.run 'save-as'
      return

    if buffer.modified_on_disk
      overwrite = interact.yes_or_no
        prompt: "Buffer '#{buffer}' has changed on disk, save anyway? "
        default: false
      unless overwrite
        log.info "Not overwriting; buffer not saved"
        return

    unless auto_mkdir buffer.file.parent
      log.info "Parent directory doesn't exist; buffer not saved"
      return

    buffer\save!
    log.info ("%s: %d lines, %d bytes written")\format buffer.file.basename,
      #buffer.lines, #buffer

command.alias 'save', 'w'

command.register
  name: 'save-as',
  description: 'Saves the current buffer to a given file'
  interactive: true
  evade_history: true
  handler: ->
    file = interact.select_file allow_new: true
    return unless file
    if file.exists
      unless interact.yes_or_no prompt: "File '#{file}' already exists, overwrite? "
        log.info "Not overwriting; buffer not saved"
        return

    unless auto_mkdir file.parent
      log.info "Parent directory doesn't exist; buffer not saved"
      return

    buffer = app.editor.buffer
    buffer\save_as file
    log.info ("%s: %d lines, %d bytes written")\format buffer.file.basename,
      #buffer.lines, #buffer

command.register
  name: 'buffer-close',
  description: 'Closes the current buffer'
  evade_history: true
  handler: ->
    buffer = app.editor.buffer
    app\close_buffer buffer

command.alias 'buffer-close', 'close'

command.register
  name: 'vc-diff-file',
  description: 'Shows a diff against the VC for the current file'
  evade_history: true
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
  evade_history: true
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
