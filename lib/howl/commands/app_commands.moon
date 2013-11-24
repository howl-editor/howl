-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app, command, config, bindings, bundle, signal, inputs from howl
import ActionBuffer, List from howl.ui
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
  name: 'run'
  description: 'Runs a command'
  handler: -> command.run!

command.register
  name: 'new-buffer',
  description: 'Opens a new buffer'
  handler: -> _G.editor.buffer = howl.app\new_buffer!

command.register
  name: 'switch-buffer',
  description: 'Switches to another buffer'
  inputs: { 'buffer' }
  handler: (buffer) -> _G.editor.buffer = buffer

command.register
  name: 'reload-buffer',
  description: 'Reloads the current buffer from file'
  handler: -> _G.editor.buffer\reload!

command.register
  name: 'switch-to-last-hidden-buffer',
  description: 'Switches to the last active hidden buffer'
  handler: ->
    for buffer in *howl.app.buffers
      if not buffer.showing
        _G.editor.buffer = buffer
        return

    _G.log.error 'No hidden buffer found'

command.register
  name: 'set',
  description: 'Sets a configuration variable'
  inputs: { '*variable_assignment' }
  handler: (assignment) ->
    if assignment.name
      value = assignment.value or ''
      if config.definitions[assignment.name]
        config.set assignment.name, value
        _G.log.info ('"%s" is now set to "%s"')\format assignment.name, assignment.value
      else
        log.error "Undefined variable '#{assignment.name}'"

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
      buffer\append 'Key translations (usable from keymap):\n', 'comment'
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
  name: 'describe-signal',
  description: 'Describes a given signal'
  inputs: { 'signal' }
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
  inputs: { '*loaded_bundle' }
  handler: (name) ->
    log.info "Unloading bundle '#{name}'.."
    bundle.unload name
    log.info "Unloaded bundle '#{name}'"

command.register
  name: 'bundle-load'
  description: 'Loads a specified, currently unloaded, bundle'
  inputs: { '*unloaded_bundle' }
  handler: (name) ->
    log.info "Loading bundle '#{name}'.."
    bundle.load_by_name name
    log.info "Loaded bundle '#{name}'"

command.register
  name: 'bundle-reload'
  description: 'Reloads a specified bundle'
  inputs: { '*loaded_bundle' }
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
  inputs: {
    ->
      buffer = editor.buffer
      inputs.line "Buffer grep in #{buffer.title}", buffer
  }
  handler: (line) -> editor.cursor.line = line.nr

command.register
  name: 'buffer-structure'
  description: 'Shows the structure for the given buffer'
  inputs: {
    ->
      buffer = editor.buffer
      inputs.line "Structure for #{buffer.title}", buffer, buffer.mode\structure editor
  }
  handler: (line) -> editor.cursor.line = tonumber line.nr
