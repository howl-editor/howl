-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, breadcrumbs, Buffer, command, config, bindings, bundle, interact, signal, mode, Project from howl
import ActionBuffer, ProcessBuffer, BufferPopup, StyledText from howl.ui
import Process from howl.io
serpent = require 'serpent'

command.register
  name: 'quit',
  description: 'Quit the application'
  handler: -> howl.app\quit!

command.alias 'quit', 'q'

command.register
  name: 'save-and-quit',
  description: 'Save modified buffers and quit the application'
  handler: ->
    with howl.app
      \quit! if \save_all!

command.alias 'save-and-quit', 'wq'

command.register
  name: 'quit-without-save',
  description: 'Quit the application, disregarding any modified buffers'
  handler: -> howl.app\quit true

command.alias 'quit-without-save', 'q!'

command.register
  name: 'run'
  description: 'Run a command'
  handler: command.run

command.register
  name: 'new-buffer',
  description: 'Opens a new buffer'
  handler: ->
    breadcrumbs.drop!
    app.editor.buffer = howl.app\new_buffer!

command.register
  name: 'switch-buffer',
  description: 'Switch to another buffer'
  input: interact.select_buffer
  handler: (buf) ->
    breadcrumbs.drop!
    app.editor.buffer = buf

command.register
  name: 'buffer-reload',
  description: 'Reload the current buffer from file'
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
  description: 'Switch to the last active hidden buffer'
  handler: ->
    for buffer in *howl.app.buffers
      if not buffer.showing
        breadcrumbs.drop!
        app.editor.buffer = buffer
        return

    _G.log.error 'No hidden buffer found'

command.register
  name: 'set',
  description: 'Set a configuration variable'
  input: interact.get_variable_assignment
  handler: (variable_assignment) ->
    target = variable_assignment.target
    target[variable_assignment.var] = variable_assignment.value

    _G.log.info ('"%s" is now set to "%s" for %s')\format variable_assignment.var, variable_assignment.value, variable_assignment.scope_name

command.register
  name: 'describe-key',
  description: 'Show information for a key'
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
  description: 'Describe a given signal'
  input: interact.select_signal
  handler: (signal_name) ->
    def = signal.all[signal_name]
    error "Unknown signal '#{signal_name}'" unless def
    buffer = with ActionBuffer!
      .title = "Signal: #{signal_name}"
      \append "#{def.description}\n\n"
      \append "Parameters:"

    params = def.parameters
    if not params
      buffer\append "None"
    else
      buffer\append '\n\n'
      buffer\append StyledText.for_table [ { name, desc } for name, desc in pairs params ], {
        { header: 'Name', style: 'string'},
        { header: 'Description', style: 'comment' }
      }

    buffer.read_only = true
    buffer.modified = false
    howl.app\add_buffer buffer

command.register
  name: 'bundle-unload'
  description: 'Unload a specified bundle'
  input: interact.select_loaded_bundle
  handler: (name) ->
    log.info "Unloading bundle '#{name}'.."
    bundle.unload name
    log.info "Unloaded bundle '#{name}'"

command.register
  name: 'bundle-load'
  description: 'Load a specified, currently unloaded, bundle'
  input: interact.select_unloaded_bundle
  handler: (name) ->
    log.info "Loading bundle '#{name}'.."
    bundle.load_by_name name
    log.info "Loaded bundle '#{name}'"

command.register
  name: 'bundle-reload'
  description: 'Reload a specified bundle'
  input: interact.select_loaded_bundle
  handler: (name) ->
    log.info "Reloading bundle '#{name}'.."
    bundle.unload name if _G.bundles[name]
    bundle.load_by_name name
    log.info "Reloaded bundle '#{name}'"

command.register
  name: 'bundle-reload-current'
  description: 'Reload the last active bundle (with files open)'
  handler: ->
    for buffer in *app.buffers
      bundle_name = buffer.file and bundle.from_file(buffer.file) or nil
      if bundle_name
        command.bundle_reload bundle_name
        return

    log.warn 'Could not find any currently active bundle to reload'

command.register
  name: 'buffer-grep'
  description: 'Show buffer lines containing boundary and exact matches in real time'
  input: ->
    command_line = app.window.command_line
    command_line\add_keymap
        binding_for: ['buffer-grep']: -> command_line\switch_to 'buffer-grep-regex'
    command_line\add_help
      key_for: 'buffer-grep'
      action: 'Switch to regular expression search'

    buffer = app.editor.buffer
    return interact.select_line
      title: "Buffer grep in #{buffer.title}"
      editor: app.editor
      lines: buffer.lines

  handler: (selection) ->
    breadcrumbs.drop!
    app.editor.cursor\move_to line: selection.line.nr, column: selection.column

command.register
  name: 'buffer-grep-exact'
  description: 'Show buffer lines containing exact matches in real time'
  input: ->
    command_line = app.window.command_line
    command_line\add_keymap
        binding_for: ['buffer-grep']: -> command_line\switch_to 'buffer-grep'
    command_line\add_help
      key_for: 'buffer-grep'
      action: 'Switch to default search'

    buffer = app.editor.buffer
    return interact.select_line
      title: "Buffer grep exact in #{buffer.title}"
      editor: app.editor
      lines: buffer.lines
      find: (query, text) ->
        start_pos, end_pos = text\ufind query, 1, true
        if start_pos
          return {{start_pos, end_pos - start_pos + 1}}

  handler: (selection) ->
    breadcrumbs.drop!
    app.editor.cursor\move_to line: selection.line.nr, column:  selection.column

command.register
  name: 'buffer-grep-regex'
  description: 'Show buffer lines containing regular expression matches in real time'
  input: ->
    command_line = app.window.command_line
    command_line\add_keymap
        binding_for: ['buffer-grep']: -> command_line\switch_to 'buffer-grep-exact'
    command_line\add_help
      key_for: 'buffer-grep'
      action: 'Switch to exact search'

    buffer = app.editor.buffer
    return interact.select_line
      title: "Buffer grep regex in #{buffer.title}"
      editor: app.editor
      lines: buffer.lines
      find: (query, text) ->
        ok, rex = pcall -> r(query)
        return unless ok

        start_pos, end_pos = rex\find text
        if start_pos
          return {{start_pos, end_pos - start_pos + 1}}
  handler: (selection) ->
    breadcrumbs.drop!
    app.editor.cursor\move_to line: selection.line.nr, column:  selection.column

command.register
  name: 'buffer-structure'
  description: 'Show the structure for the current buffer'
  input: ->
    buffer = app.editor.buffer
    lines = buffer.mode\structure app.editor
    cursor_lnr = app.editor.cursor.line

    local selected_line
    for line in *lines
      if line.nr <= cursor_lnr
        selected_line = line
      if line.nr >= cursor_lnr
        break

    return interact.select_line
      title: "Structure for #{buffer.title}"
      :lines
      :selected_line

  handler: (selection) ->
    breadcrumbs.drop!
    app.editor.cursor\move_to line: selection.line.nr, column: selection.column

command.register
  name: 'navigate-back'
  description: 'Goes back to the last location recorded'
  handler: ->
    if breadcrumbs.previous
      breadcrumbs.go_back!
      log.info "navigate: now at #{breadcrumbs.location} of #{#breadcrumbs.trail}"
    else
      log.info "No previous location recorded"

command.register
  name: 'navigate-forward'
  description: 'Goes to the next location recorced'
  handler: ->
    if breadcrumbs.next
      breadcrumbs.go_forward!
      log.info "navigate: now at #{breadcrumbs.location} of #{#breadcrumbs.trail}"
    else
      log.info "No next location recorded"

-----------------------------------------------------------------------
-- Howl eval commands
-----------------------------------------------------------------------

do_howl_eval = (load_f, mode_name, transform_f) ->
  editor = app.editor
  text = editor.selection.empty and editor.current_line.text or editor.selection.text
  text = transform_f and transform_f(text) or text

  f = assert load_f text
  ret = { pcall f }
  if ret[1]
    out = ''
    for i = 2, #ret
      out ..= "\n#{serpent.block ret[i], comment: false}"

    if editor.popup
      log.info "(Eval) => #{ret[2]}"
    else
      buf = Buffer mode.by_name mode_name
      buf.text = "-- Howl eval (#{mode_name}) =>#{out}"
      editor\show_popup BufferPopup buf, scrollable: true
    howl.clipboard.push out
  else
    log.error "(ERROR) => #{ret[2]}"

command.register
  name: 'howl-lua-eval'
  description: 'Eval the current line or selection as Lua'
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
  description: 'Eval the current line or selection as Moonscript'
  handler: ->
    moonscript = require('moonscript')
    transform = (text) ->
      initial_indent = text\match '^([ \t]*)%S'
      if initial_indent -- remove the initial indent from all lines if any
        lines = [l\gsub("^#{initial_indent}", '') for l in text\gmatch('[^\n]+')]
        text = table.concat lines, '\n'

      moonscript.loadstring text

    do_howl_eval transform, 'moonscript'

command.register
  name: 'howl-moon-print'
  description: 'Compile and show the Lua for the current buffer or selection'
  handler: ->
    moonscript = require('moonscript.base')
    editor = app.editor
    buffer = editor.buffer
    title = "#{buffer.title} (compiled to Lua)"
    text = buffer.text

    unless editor.selection.empty
      title = "#{buffer.title} (Lua - from selection)"
      text = editor.selection.text

    lua, err = moonscript.to_lua text
    local buf
    if not lua
      buf = ActionBuffer!
      buf\append howl.ui.markup.howl "<error>#{err}</error>"
    else
      buf = Buffer mode.by_name 'lua'
      buf.text = lua

    buf.title = title
    buf.modified = false

    if #buf.lines > 20
      breadcrumbs.drop!
      editor.buffer = buf
    else
      buf\insert "-- #{title}\n", 1
      editor\show_popup BufferPopup buf, scrollable: true

-----------------------------------------------------------------------
-- Launch commands
-----------------------------------------------------------------------

launch_cmd = (working_directory, cmd) ->
  shell = howl.sys.env.SHELL
  p = Process {
    :cmd,
    :shell,
    read_stdout: true,
    read_stderr: true,
    working_directory: working_directory,
  }

  breadcrumbs.drop!
  buffer = ProcessBuffer p
  editor = app\add_buffer buffer
  editor.cursor\eof!
  buffer\pump!

get_project_root = ->
  buffer = app.editor and app.editor.buffer
  file = buffer.file or buffer.directory
  error "No file associated with the current view" unless file
  project = Project.get_for_file file
  error "No project associated with #{file}" unless project
  return project.root

command.register
  name: 'project-exec',
  description: 'Run an external command from within the project directory'
  input: -> interact.get_external_command path: get_project_root!
  handler: launch_cmd

command.register
  name: 'project-build'
  description: 'Run the command in config.project_build_command from within the project directory'
  handler: -> launch_cmd get_project_root!, config.project_build_command

command.register
  name: 'exec',
  description: 'Run an external command'
  input: (path=nil) -> interact.get_external_command :path
  handler: launch_cmd

command.register
  name: 'save-config'
  description: 'Save the current configuration'
  handler: ->
    config.save_config!
    log.info 'Configuration saved'

config.define
  name: 'project_build_command'
  description: 'The command to execute when project-build is run'
  default: 'make'
  type_of: 'string'
