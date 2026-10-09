-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:style, :StyledText} = howl.ui

icons = {}

-- Icon glyphs differ in width, but drawn small they're all narrower than two
-- monospace characters. Lists of rows starting with icons use tabs this wide, and
-- follow each icon with a tab, so that the texts after the icons line up.
list_tab_size = 2

list_tab = StyledText '\t', {}

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

get = (name, icon_style = 'icon') ->
  icon = name
  while type(icon) == 'string'
    name = icon
    icon = icons[name]
    error "Invalid icon '#{name}'", 2 unless icon

  icon_style = style_name(name) .. ':' .. icon_style
  text = icon.text
  return StyledText(text, {1, icon_style, #text + 1})

-- the styled icon, as returned by get, followed by the tab lining up the text
-- after it in a list with list_tab_size
list_cell = (styled_icon) -> styled_icon .. list_tab

{
  :define
  :define_default
  :get
  :list_cell
  :list_tab_size
}
