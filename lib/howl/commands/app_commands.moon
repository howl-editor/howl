-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, Buffer, command, config, bindings, bundle, dispatch, interact, signal, inputs, mode, Project from howl
import ActionBuffer, ProcessBuffer, BufferPopup, StyledTable from howl.ui
import File, Process from howl.io
serpent = require 'serpent'

command.register
  name: 'quit',
  description: 'Quits the application'
  handler: -> howl.app\quit!

command.alias 'quit', 'q'

command.register
  name: 'save-and-quit',
  description: 'Saves modified buffers and quits the application'
  handler: ->
    with howl.app
      \quit! if \save_all!

command.alias 'save-and-quit', 'wq'

command.register
  name: 'quit-without-save',
  description: 'Quits the application, disregarding any modified buffers'
  handler: -> howl.app\quit true

command.alias 'quit-without-save', 'q!'

command.register
  name: 'run'
  description: 'Runs a command'
  handler: -> command.run!

command.register
  name: 'new-buffer',
  description: 'Opens a new buffer'
  handler: -> app.editor.buffer = howl.app\new_buffer!

command.register
  name: 'switch-buffer',
  description: 'Switches to another buffer'
  handler: ->
    buf = interact.select_buffer!
    if buf
      app.editor.buffer = buf

command.register
  name: 'buffer-reload',
  description: 'Reloads the current buffer from file'
  handler: ->
    buffer = app.editor.buffer
    if buffer.modified
      unless interact.yes_or_no prompt: 'Buffer is modified, reload anyway? '
        log.info "Not reloading; buffer is untouched"
        return

    buffer\reload true
    log.info "Buffer reloaded from file"

command.register
  name: 'switch-to-last-hidden-buffer',
  description: 'Switches to the last active hidden buffer'
  handler: ->
    for buffer in *howl.app.buffers
      if not buffer.showing
        app.editor.buffer = buffer
        return

    _G.log.error 'No hidden buffer found'

set_variable = (assignment, target) ->
  if assignment
    value = assignment.value
    if config.definitions[assignment.name]
      target[assignment.name] = value
      _G.log.info ('"%s" is now set to "%s"')\format assignment.name, assignment.value
    else
      log.error "Undefined variable '#{assignment.name}'"

command.register
  name: 'set',
  description: 'Sets a configuration variable globally'
  handler: -> set_variable interact.get_variable_assignment!, config

command.register
  name: 'set-for-mode',
  description: 'Sets a configuration variable for the current mode'
  handler: -> set_variable interact.get_variable_assignment!, app.editor.buffer.mode.config

command.register
  name: 'set-for-buffer',
  description: 'Sets a configuration variable for the current buffer'
  handler: -> set_variable interact.get_variable_assignment!, app.editor.buffer.config

command.register
  name: 'describe-key',
  description: 'Shows information for a key'
  handler: ->
    buffer = ActionBuffer!
    buffer.title = 'Key watcher'
    buffer\append 'Press any key to show information for it (press escape to quit)..\n\n', 'string'
    editor = howl.app\add_buffer buffer
    editor.cursor\eof!

    bindings.capture (event, source, translations) ->
      buffer.lines\delete 3, #buffer.lines
      buffer\append 'Key translations (usable from bindings):\n', 'comment'
      buffer\append serpent.block translations, comment: false
      buffer\append '\n\nKey event:\n', 'comment'
      buffer\append serpent.block event, comment: false
      bound_commands = {}
      for t in *translations
        cmd = bindings.action_for t
        cmd = '<function>' if typeof(cmd) == 'function'
        bound_commands[t] = cmd
      buffer\append '\n\nBound command:\n', 'comment'
      buffer\append serpent.block bound_commands, comment: false

      if event.key_name == 'escape'
        buffer.lines[1] = '(Snooping done, close this buffer at your leisure)'
        buffer\style 1, #buffer, 'comment'
        buffer.modified = false
      else
        return false

command.register
  name: 'describe-signal',
  description: 'Describes a given signal'
  handler: ->
    name = interact.select_signal!
    def = signal.all[name]
    error "Unknown signal '#{name}'" unless def
    buffer = with ActionBuffer!
      .title = "Signal: #{name}"
      \append "#{def.description}\n\n"
      \append "Parameters:"

    params = def.parameters
    if not params
      buffer\append "None"
    else
      buffer\append '\n\n'
      buffer\append StyledTable [ { name, desc } for name, desc in pairs params ], {
        { header: 'Name', style: 'string'},
        { header: 'Description', style: 'comment' }
      }

    buffer.read_only = true
    buffer.modified = false
    editor = howl.app\add_buffer buffer

command.register
  name: 'bundle-unload'
  description: 'Unloads a specified bundle'
  handler: ->
    name = interact.select_loaded_bundle!
    return if not name

    log.info "Unloading bundle '#{name}'.."
    bundle.unload name
    log.info "Unloaded bundle '#{name}'"

command.register
  name: 'bundle-load'
  description: 'Loads a specified, currently unloaded, bundle'
  handler: ->
    name = interact.select_unloaded_bundle!
    return if not name

    log.info "Loading bundle '#{name}'.."
    bundle.load_by_name name
    log.info "Loaded bundle '#{name}'"

command.register
  name: 'bundle-reload'
  description: 'Reloads a specified bundle'
  handler: ->
    name = interact.select_loaded_bundle!
    return if not name

    log.info "Reloading bundle '#{name}'.."
    bundle.unload name if _G.bundles[name]
    bundle.load_by_name name
    log.info "Reloaded bundle '#{name}'"

command.register
  name: 'bundle-reload-current'
  description: 'Reloads the last active bundle (with files open)'
  handler: ->
    for buffer in *app.buffers
      bundle_name = buffer.file and bundle.from_file(buffer.file) or nil
      if bundle_name
        howl.app.window.command_line\run_after_finish ->
          command.run "bundle-reload #{bundle_name}"
        return

    log.warn 'Could not find any currently active bundle to reload'

command.register
  name: 'buffer-grep'
  description: 'Matches certain buffer lines in realtime'
  handler: ->
    buffer = app.editor.buffer
    position = interact.select_match
      title: "Buffer grep in #{buffer.title}"
      editor: app.editor

    if position
       app.editor.cursor\move_to position.row, position.col


command.register
  name: 'buffer-structure'
  description: 'Shows the structure for the given buffer'
  handler: ->
    buffer = app.editor.buffer
    lines = buffer.mode\structure app.editor
    position = interact.select_match
      title: "Structure for #{buffer.title}"
      editor: app.editor
      :lines
      selected_line: app.editor.cursor.line

    if position
       app.editor.cursor\move_to position.row, position.col

-----------------------------------------------------------------------
-- Howl eval commands
-----------------------------------------------------------------------

do_howl_eval = (load_f, mode_name, transform_f) ->
  editor = app.editor
  text = editor.selection.empty and editor.current_line.text or editor.selection.text
  text = text.stripped
  text = transform_f and transform_f(text) or text
  f = assert load_f text
  ret = { pcall f }
  if ret[1]
    out = ''
    for i = 2, #ret
      out ..= "\n#{serpent.block ret[i], comment: false}"

    buf = Buffer mode.by_name mode_name
    buf.text = "-- Howl eval (#{mode_name}) =>#{out}"
    editor\show_popup BufferPopup buf
    howl.clipboard.push out
   else
    log.error "(ERROR) => #{ret[2]}"

command.register
  name: 'howl-lua-eval'
  description: 'Evals the current line or selection as Lua'
  handler: ->
    do_howl_eval load, 'lua', (text) ->
      unless text\match 'return%s'
        text = if text\find '\n'
          text\gsub "\n([^\n]+)$", "\n  return %1"
        else
          "return #{text}"
      text

command.register
  name: 'howl-moon-eval'
  description: 'Evals the current line or selection as Moonscript'
  handler: ->
    moonscript = require('moonscript')
    do_howl_eval moonscript.loadstring, 'moonscript'

command.register
  name: 'howl-moon-print'
  description: 'Compiles and shows the Lua for the current buffer or selection'
  handler: ->
    moonscript = require('moonscript')
    editor = app.editor
    buffer = editor.buffer
    title = "#{buffer.title} (compiled to Lua)"
    text = buffer.text

    unless editor.selection.empty
      title = "#{buffer.title} (Lua - from selection)"
      text = editor.selection.text

    lua = moonscript.to_lua text
    buf = Buffer mode.by_name 'lua'
    buf.text = lua
    buf.title = title
    buf.modified = false

    if #buf.lines > 20
      editor.buffer = buf
    else
      buf\insert "-- #{title}\n", 1
      editor\show_popup BufferPopup buf

-----------------------------------------------------------------------
-- Launch commands
-----------------------------------------------------------------------

launch_cmd = (working_directory, cmd) ->
  dispatch.launch ->
    shell = howl.sys.env.SHELL or '/bin/sh'
    p = Process {
      :cmd,
      :shell,
      read_stdout: true,
      read_stderr: true,
      working_directory: working_directory,
    }

    buffer = ProcessBuffer p
    editor = app\add_buffer buffer
    editor.cursor\eof!
    buffer\pump!

command.register
  name: 'project-exec',
  description: 'Runs an external command from within the project directory'
  handler: ->
    buffer = app.editor and app.editor.buffer
    file = buffer.file or buffer.directory
    error "No file associated with the current view" unless file
    project = Project.get_for_file file
    error "No project associated with #{file}" unless project
    working_directory, cmd = interact.get_external_command path: project.root
    if cmd
      launch_cmd working_directory, cmd

command.register
  name: 'exec',
  description: 'Runs an external command'
  handler: ->
    working_directory, cmd = interact.get_external_command!
    if cmd
      launch_cmd working_directory, cmd
