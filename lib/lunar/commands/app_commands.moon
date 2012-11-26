import command, config, keyhandler from lunar
import ActionBuffer from lunar.ui
serpent = require 'serpent'

command.register
  name: 'q',
  description: 'Quits the application'
  handler: -> lunar.app\quit!

command.alias 'q', 'quit'

command.register
  name: 'switch-buffer',
  description: 'Switches to another buffer'
  inputs: { 'buffer' }
  handler: (buffer) ->
    _G.editor.buffer = buffer

command.register
  name: 'switch-to-last-hidden-buffer',
  description: 'Switches to the last active hidden buffer'
  handler: ->
    for buffer in *lunar.app.buffers
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
      config.set assignment.name, value
      _G.log.info ('"%s" is now set to "%s"')\format assignment.name, assignment.value

command.register
  name: 'describe-key',
  description: 'Shows information for a key'
  handler: ->
    buffer = ActionBuffer!
    buffer.title = 'Key watcher'
    buffer\append 'Press any key to show information for it (press escape to quit)..\n\n', 'error'
    editor = lunar.app\add_buffer buffer
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
