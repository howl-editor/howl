-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app, Buffer, command, config, bindings, bundle, signal, inputs, mode from howl
import ActionBuffer, BufferPopup, List from howl.ui
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
  input: 'buffer'
  handler: (buffer) -> app.editor.buffer = buffer

command.register
  name: 'buffer-reload',
  description: 'Reloads the current buffer from file'
  handler: ->
    app.editor.buffer\reload!
    log.info "Buffer reloaded from file"

command.alias 'buffer-reload', 'reload-buffer', deprecated: true

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
  if assignment.name
    value = assignment.value
    if config.definitions[assignment.name]
      target[assignment.name] = value
      _G.log.info ('"%s" is now set to "%s"')\format assignment.name, assignment.value
    else
      log.error "Undefined variable '#{assignment.name}'"

command.register
  name: 'set',
  description: 'Sets a configuration variable globally'
  input: 'variable_assignment'
  handler: (assignment) -> set_variable assignment, config

command.register
  name: 'set-for-mode',
  description: 'Sets a configuration variable for the current mode'
  input: 'variable_assignment'
  handler: (assignment) ->
    set_variable assignment, app.editor.buffer.mode.config

command.alias 'set-for-mode', 'mode-set', deprecated: true

command.register
  name: 'set-for-buffer',
  description: 'Sets a configuration variable for the current buffer'
  input: 'variable_assignment'
  handler: (assignment) ->
    set_variable assignment, app.editor.buffer.config

command.alias 'set-for-buffer', 'buffer-set', deprecated: true

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

      if event.key_name == 'escape'
        buffer.lines[1] = '(Snooping done, close this buffer at your leisure)'
        buffer\style 1, #buffer, 'comment'
        buffer.modified = false
      else
        return false

command.register
  name: 'describe-input',
  description: 'Shows information for an input'
  input: 'input'
  handler: (name) ->
    def = inputs[name]
    error "Unknown input '#{name}'" unless def
    buffer = with ActionBuffer!
      .title = "Input: #{name}"
      \append "#{def.description}\n\n"

    buffer.read_only = true
    buffer.modified = false
    editor = howl.app\add_buffer buffer

command.register
  name: 'describe-signal',
  description: 'Describes a given signal'
  input: 'signal'
  handler: (name) ->
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
      list = List buffer, #buffer + 1
      list.items = [ { name, desc } for name, desc in pairs params ]
      list.headers = { 'Name', 'Description' }
      list\show!

    buffer.read_only = true
    buffer.modified = false
    editor = howl.app\add_buffer buffer

command.register
  name: 'bundle-unload'
  description: 'Unloads a specified bundle'
  input: 'loaded_bundle'
  handler: (name) ->
    log.info "Unloading bundle '#{name}'.."
    bundle.unload name
    log.info "Unloaded bundle '#{name}'"

command.register
  name: 'bundle-load'
  description: 'Loads a specified, currently unloaded, bundle'
  input: 'unloaded_bundle'
  handler: (name) ->
    log.info "Loading bundle '#{name}'.."
    bundle.load_by_name name
    log.info "Loaded bundle '#{name}'"

command.register
  name: 'bundle-reload'
  description: 'Reloads a specified bundle'
  input: 'loaded_bundle'
  handler: (name) ->
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
        command.run "bundle-reload #{bundle_name}"
        return

    log.warn 'Could not find any currently active bundle to reload'

command.register
  name: 'buffer-grep'
  description: 'Matches certain buffer lines in realtime'
  input: ->
    buffer = app.editor.buffer
    inputs.line "Buffer grep in #{buffer.title}", app.editor

  handler: (line) -> app.editor.cursor.line = line.nr

command.register
  name: 'buffer-structure'
  description: 'Shows the structure for the given buffer'
  input: ->
    buffer = app.editor.buffer
    inputs.line "Structure for #{buffer.title}", app.editor, buffer.mode\structure app.editor

  handler: (line) -> app.editor.cursor.line = tonumber line.nr

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
