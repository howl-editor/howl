-- Copyright 2012-2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import app, command, config from howl
import style from howl.ui

command.register
  name: 'window-toggle-fullscreen',
  description: 'Toggles fullscreen for the current window'
  handler: -> app.window.fullscreen = not app.window.fullscreen

command.register
  name: 'window-toggle-maximized',
  description: 'Toggles maximized state for the current window'
  handler: -> app.window.maximized = not app.window.maximized

command.register
  name: 'describe-style',
  description: 'Describes the current style at cursor'
  handler: ->
    name, def = style.at_pos app.editor.buffer, app.editor.cursor.pos
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
  { 'left', 'left_of', 'Goes to the left view, creating it if necessary' }
  { 'right', 'right_of', 'Goes to the right view, creating it if necessary' }
  { 'up', 'above', 'Goes to the view above, creating it if necessary' }
  { 'down', 'below', 'Goes to the view below, creating it if necessary' }
}
  { direction, placement, description } = cmd
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
