import command, config from howl
import style from howl.ui

command.register
  name: 'toggle-fullscreen',
  description: 'Toggles fullscreen for the current window'
  handler: -> _G.window\toggle_fullscreen!

command.register
  name: 'describe-style',
  description: 'Describes the current style at cursor'
  handler: ->
    name, def = style.at_pos _G.editor.buffer, _G.editor.cursor.pos
    log.info "#{name}"

command.register
  name: 'zoom-in',
  description: 'Increases the current font size by 1 (globally)'
  handler: ->
    size = config.font_size + 1
    config.font_size = size
    log.info "zoom-in: global font size set to #{size}"

command.register
  name: 'zoom-out',
  description: 'Decreases the current font size by 1 (globally)'
  handler: ->
    size = config.font_size - 1
    if size <= 6
      log.error 'zoom-out: minimum font size reached (6)'
    else
      config.font_size = size
      log.info "zoom-out: global font size set to #{size}"
