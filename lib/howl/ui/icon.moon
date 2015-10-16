-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import style, StyledText from howl.ui

icons = {}

style_name = (icon_name) -> '_icon_font_'..icon_name

define = (name, definition={}) ->
  unless definition.text or type(definition) == 'string'
    error "Definition must be string or contain field 'text'"
  if type(definition) == 'string'
    icons[name] = definition
  else
    style.define style_name(name),
      font: definition.font
    icons[name] = {:name, text: definition.text, font: definition.font}

define_default = (name, definition) ->
  define(name, definition) unless icons[name]

get = (name, style='icon') ->
  icon = name
  while type(icon) == 'string'
    name = icon
    icon = icons[name]
    error "Invalid icon '#{name}'" unless icon

  style = style_name(name) .. ':' .. style
  text = icon.text
  return StyledText(text, {1, style, #text + 1})

{
  :define
  :define_default
  :get
}
