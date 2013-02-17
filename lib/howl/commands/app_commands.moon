import command, config, keyhandler, bundle from howl
import ActionBuffer from howl.ui
serpent = require 'serpent'

command.register
  name: 'q',
  description: 'Quits the application'
  handler: -> howl.app\quit!

command.alias 'q', 'quit'

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
  inputs: { 'variable_assignment' }
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

    keyhandler.capture (event, translations) ->
      buffer.lines\delete 3, #buffer.lines
      buffer\append 'Key translations (usable from keymap):\n', 'comment'
      buffer\append serpent.block translations, comment: false
      buffer\append '\n\nKey event:\n', 'comment'
      buffer\append serpent.block event, comment: false

      if event.key_name == 'escape'
        buffer.lines[1] = '(Snooping done, close this buffer at your leisure)'
        buffer\style 1, #buffer, 'comment'
      else
        return false

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
    bundle.unload name
    bundle.load_by_name name
    log.info "Reloaded bundle '#{name}'"

