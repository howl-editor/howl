import command, config from howl
import style from howl.ui

command.register
  name: 'toggle-fullscreen',
  description: 'Toggles fullscreen for the current window'
  handler: -> _G.window.fullscreen = not _G.window.fullscreen

command.register
  name: 'toggle-maximized',
  description: 'Toggles maximized state for the current window'
  handler: -> _G.window.maximized = not _G.window.maximized

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

command.register
  name: "close-view",
  description: "Closes the current view"
  handler: ->
    if #window.views > 1
      window\remove_view!
      collectgarbage!
    else
      log.error "Can't close the one remaining view"

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
      target = window\siblings![direction]
      if target
        target\grab_focus!
      else
        log.info "No view #{human_placement} the current one found"

  command.register
    name: "view-#{direction}-wraparound",
    description: "Goes to the view #{human_placement} the current one if present"
    handler: ->
      target = window\siblings(true)[direction]
      if target
        target\grab_focus!
      else
        log.info "No view #{human_placement} the current one found"

  command.register
    name: "view-#{direction}-or-create",
    description: "Goes to the view #{human_placement} the current one, creating it if necessary"
    handler: ->
      target = window\siblings![direction]
      if target
        target\grab_focus!
      else
        howl.app\new_editor :placement

  command.register
    name: "new-view-#{placement\gsub '_', '-'}",
    description: "Adds a new view #{human_placement} the current one"
    handler: -> howl.app\new_editor :placement
