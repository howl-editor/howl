-- Copyright 2012-2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import app, command, config, mode from howl
import style, ActionBuffer, BufferPopup, StyledText from howl.ui
serpent = require 'serpent'

command.register
  name: 'window-toggle-fullscreen',
  description: 'Toggle fullscreen for the current window'
  handler: -> app.window.fullscreen = not app.window.fullscreen

command.register
  name: 'window-toggle-maximized',
  description: 'Toggle maximized state for the current window'
  handler: -> app.window.maximized = not app.window.maximized

command.register
  name: 'describe-style',
  description: 'Describe the current style at cursor'
  handler: ->
    name = style.at_pos app.editor.buffer, app.editor.cursor.pos
    unless name
      log.info "Unstyled"
      return

    def = style[name]
    editor = app.editor
    buf = ActionBuffer!
    buf\append name, 'h1'
    buf\append "\n\n"
    def_s = serpent.block def, comment: false
    lua_mode = mode.by_name 'lua'

    if lua_mode
      styles = lua_mode.lexer(def_s)
      def_s = StyledText def_s, styles

    buf\append def_s
    editor\show_popup BufferPopup buf

command.register
  name: 'zoom-in',
  description: 'Increase the current font size by 1 (globally)'
  handler: ->
    size = config.font_size + 1
    config.font_size = size
    log.info "zoom-in: global font size set to #{size}"

command.register
  name: 'zoom-out',
  description: 'Decrease the current font size by 1 (globally)'
  handler: ->
    size = config.font_size - 1
    if size <= 6
      log.error 'zoom-out: minimum font size reached (6)'
    else
      config.font_size = size
      log.info "zoom-out: global font size set to #{size}"

command.register
  name: "view-close",
  description: "Closes the current view"
  handler: ->
    if #app.window.views > 1
      app.window\remove_view!
      collectgarbage!
    else
      log.error "Can't close the one remaining view"

command.register
  name: "view-next",
  description: "Focuses the next view, wrapping around as necessary"
  handler: ->
    target = app.window\siblings(nil, true).right
    if target
      target\grab_focus!
    else
      log.warn "No other view found"

for cmd in *{
  { 'left', 'left_of' }
  { 'right', 'right_of' }
  { 'up', 'above' }
  { 'down', 'below' }
}
  { direction, placement } = cmd
  human_placement = placement\gsub '_', ' '

  command.register
    name: "view-#{direction}",
    description: "Goes to the view #{human_placement} the current one if present"
    handler: ->
      target = app.window\siblings![direction]
      if target
        target\grab_focus!
      else
        log.info "No view #{human_placement} the current one found"

  command.register
    name: "view-#{direction}-wraparound",
    description: "Goes to the view #{human_placement} the current one if present"
    handler: ->
      target = app.window\siblings(true)[direction]
      if target
        target\grab_focus!
      else
        log.info "No view #{human_placement} the current one found"

  command.register
    name: "view-#{direction}-or-create",
    description: "Goes to the view #{human_placement} the current one, creating it if necessary"
    handler: ->
      target = app.window\siblings![direction]
      if target
        target\grab_focus!
      else
        howl.app\new_editor :placement

  command.register
    name: "view-new-#{placement\gsub '_', '-'}",
    description: "Adds a new view #{human_placement} the current one"
    handler: -> howl.app\new_editor :placement
