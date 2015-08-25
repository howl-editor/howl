-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
Gtk = require 'ljglibs.gtk'
Gdk = require 'ljglibs.gdk'
require 'ljglibs.gtk.widget'

import File from howl.io
import config, signal from howl
import style, colors, highlight from howl.ui
import PropertyTable, Sandbox from howl.aux

css_provider = Gtk.CssProvider!
screen = Gdk.Screen\get_default!
Gtk.StyleContext.add_provider_for_screen screen, css_provider, 600

css_template = [[
GtkWindow.main {
  background-color: ${editor_background_color};
  ${window_background};
}

.editor {
  border-width: 1px 3px 3px 1px;
  background-color: ${editor_border_color};
}

.sci_box {
  background-color: ${editor_divider_color};
}

.sci_container {
  background-color: ${editor_background_color};
}

.header {
  ${header_background};
  color: ${header_color};
  font: ${header_font};
  border-width: 0px;
}

.footer {
  ${footer_background};
  color: ${footer_color};
  font: ${footer_font};
  border-width: 0px;
}

.status {
  font: ${status_font};
  color: ${status_color};
}

]]

status_template = [[
.status_${name} {
  font: ${font};
  color: ${color};
}
]]

theme_files = {}
current_theme = nil
current_theme_file = nil
theme_active = false
scis = setmetatable {}, __mode: 'k'
background_color_widgets = setmetatable {}, __mode: 'k'

interpolate = (content, values) ->
  content\gsub '%${([%a_]+)}', values

apply_sci_visuals = (theme, sci) ->
  v = theme.editor
  -- caret
  c_color = '#000000'
  c_width = 1

  if v.caret
    c_color = v.caret.color if v.caret.color
    c_width = v.caret.width if v.caret.width

  current_line = v.current_line
  selection = v.selection

  with sci
    \set_caret_fore c_color
    \set_caret_width c_width

    if current_line and current_line.background
      \set_caret_line_back current_line.background

    if selection
      \set_sel_back true, selection.background if selection.background
      \set_sel_fore true, selection.color if selection.color

parse_background = (value, theme_dir) ->
  if value\match '^%s*#%x+%s*$'
    'background-color: ' .. value
  elseif value\find '-gtk-gradient', 1, true
    'background-image: ' .. value
  else
    if not File.is_absolute value
      value = tostring theme_dir\join(value).path
    "background-image: url('" .. value .. "')"

parse_font = (font = {}) ->
  size = config.font_size
  desc = config.font
  desc ..= ' bold' if font.bold
  desc ..= ' italic' if font.italic
  desc ..= ' ' .. size if size
  desc

indicator_css = (id, def) ->
  clazz = '.indic_' .. id
  indic_css = clazz .. ' { '
  if def.color then indic_css ..= 'color: ' .. def.color .. '; '
  indic_css ..= 'font: ' .. parse_font(def.font).. '; '
  indic_css ..= ' }\n'
  indic_css

indicators_css = (indicators = {}) ->
  css = indicator_css 'default', indicators.default or {}
  for id, def in pairs indicators
    css ..= indicator_css id, def if id != 'default'
  css

status_css = (status) ->
  css = ''
  for level in *{'info', 'warning', 'error'}
    values = status[level]
    if values
      font = values.font or status.font
      color = values.color or status.color
      css ..= interpolate status_template,
        name: level
        font: parse_font font
        color: color
  css

theme_css = (theme, file) ->
  dir = file.parent
  window = theme.window
  status = window.status
  editor = theme.editor
  hdr = editor.header
  footer = editor.footer
  tv_title = hdr.title
  indicators = editor.indicators
  values =
    editor_background_color: theme.styles.default.background
    window_background: parse_background(window.background, dir)
    status_font: parse_font status.font
    status_color: status.color
    editor_border_color: editor.border_color
    editor_divider_color: editor.divider_color
    header_background: parse_background(hdr.background, dir)
    header_color: hdr.color
    header_font: parse_font hdr.font
    footer_background: parse_background(footer.background, dir)
    footer_color: footer.color
    footer_font: parse_font footer.font
  css = interpolate css_template, values
  css ..= indicators_css indicators
  css ..= status_css status
  css

load_theme = (file) ->
  chunk = loadfile(file.path)
  box = Sandbox colors
  box\put :highlight
  box chunk

override_widget_background = (widget, background_style) ->
  if theme_active
    style_def = current_theme.styles[background_style]
    bg_color = style_def and style_def.background
    if not bg_color and style != 'default'
      style_def = current_theme.styles.default
      bg_color = style_def and style_def.background

    if bg_color
      background = Gdk.RGBA!
      background\parse bg_color
      widget\override_background_color 0, background

apply_theme = ->
  css = theme_css current_theme, current_theme_file
  status = css_provider\load_from_data css
  error 'Error applying theme "' .. current_theme.name .. '"' if not status
  style.set_for_theme current_theme
  highlight.set_for_theme current_theme
  apply_sci_visuals current_theme, sci for sci in pairs scis
  override_widget_background widget, style for widget, style in pairs background_color_widgets

set_theme = (name) ->
  if name == nil
    current_theme = nil
    theme_active = false
    return

  file = theme_files[name]
  error 'No theme found with name "' .. name .. '"' if not file
  status, ret = pcall load_theme, file
  error "Error applying theme '#{name}: #{ret}'" if not status
  theme = ret
  theme.name = name
  current_theme = theme
  current_theme_file = file
  if theme_active
    apply_theme!
    signal.emit 'theme-changed', :theme

with config
  .define
    name: 'theme'
    description: 'The theme to use (colors, styles, highlights, etc.)'
    default: 'Solarized Light'
    type_of: 'string'
    options: -> [name for name in pairs theme_files]
    scope: 'global'

  .define
    name: 'font'
    description: 'The main font used within the application'
    default: if ffi.os == 'OSX' then 'Monaco' else 'Liberation Mono'
    type_of: 'string'
    scope: 'global'

  .define
    name: 'font_size'
    description: 'The size of the main font'
    default: 11
    type_of: 'number'
    scope: 'global'

config.watch 'theme', (_, name) ->
  set_theme name

config.watch 'font', (name, value) -> apply_theme! if current_theme
config.watch 'font_size', (name, value) -> apply_theme! if current_theme

signal.register 'theme-changed',
  description: 'Signaled after a theme has been applied'
  parameters:
    theme: 'The theme that has been set'

return PropertyTable {
  current: get: -> current_theme

  all: theme_files

  register: (name, file) ->
    error 'name not specified for theme', 2 if not name
    error 'file not specified for theme', 2 if not file
    theme_files[name] = file

    if current_theme and current_theme.name == name
      set_theme name

  unregister: (name) ->
    theme_files[name] = nil

  apply: ->
    return if theme_active
    set_theme config.theme unless current_theme
    error 'No theme set to apply', 2 unless current_theme
    apply_theme!
    theme_active = true

  register_sci: (sci) ->
    scis[sci] = true
    apply_sci_visuals current_theme, sci if theme_active

  register_background_widget: (widget, style = 'default') ->
    background_color_widgets[widget] = style
    override_widget_background widget, style

  unregister_background_widget: (widget) ->
    background_color_widgets[widget] = nil
}
