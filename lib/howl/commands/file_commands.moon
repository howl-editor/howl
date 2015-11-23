-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, command, mode, interact, Buffer, Project from howl
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
  input: -> interact.select_file allow_new: true
  handler: (file) -> app\open_file file

command.register
  name: 'open-recent',
  description: 'Open a recently visited file'
  input: ->
    recent_files = {}
    for buf in *app.buffers
      table.insert recent_files, {
        buf.title,
        buf.file.parent.short_path,
        file: buf.file
      }
    for file_info in *app.recently_closed
      table.insert recent_files, {
        file_info.file.basename
        file_info.file.parent.short_path
        file: file_info.file
      }
    selected = interact.select_location
      items: recent_files
      columns: { {style: 'filename'}, {style: 'comment'} }
      title: 'Recent files'
    return selected and selected.selection.file

  handler: app\open_file

command.alias 'open', 'e'

command.register
  name: 'project-open',
  description: 'Open project file'
  input: ->
    buffer = app.editor and app.editor.buffer
    file = buffer and (buffer.file or buffer.directory)
    if file
      project = Project.get_for_file file
      if project
        return interact.select_file_in_project :project
    else
      log.warn "No file or directory associated with the current view"
      return
  handler: (file) ->
    app\open_file file

command.register
  name: 'save',
  description: 'Saves the current buffer to file'
  handler: ->
    buffer = app.editor.buffer
    if not buffer.file
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
  input: ->
    file = interact.select_file allow_new: true
    return unless file

    if file.exists
      unless interact.yes_or_no prompt: "File '#{file}' already exists, overwrite? "
        log.info "Not overwriting; buffer not saved"
        return

    unless auto_mkdir file.parent
      log.info "Parent directory doesn't exist; buffer not saved"
      return

    return file

  handler: (file) ->
    buffer = app.editor.buffer
    buffer\save_as file
    log.info ("%s: %d lines, %d bytes written")\format buffer.file.basename,
      #buffer.lines, #buffer

command.register
  name: 'buffer-close',
  description: 'Closes the current buffer'
  handler: ->
    buffer = app.editor.buffer
    app\close_buffer buffer

command.alias 'buffer-close', 'close'

command.register
  name: 'vc-diff-file',
  description: 'Shows a diff against the VC for the current file'
  handler: ->
    with_vc (vc, buffer) ->
      diff = vc\diff buffer.file
      if diff
        show_diff_buffer "[#{vc.name}] #{buffer.file.basename}", diff
      else
        log.info "VC: No differences found for #{buffer.file.basename}"

command.register
  name: 'vc-diff',
  description: 'Shows a diff against the VC for the current project'
  handler: ->
    with_vc (vc, buffer, project) ->
      diff = vc\diff!
      if diff
        show_diff_buffer "[#{vc.name}]: #{vc.root}", diff
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
