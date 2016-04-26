-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
Gtk = require 'ljglibs.gtk'
Gdk = require 'ljglibs.gdk'
require 'ljglibs.gtk.widget'
flair = require 'aullar.flair'

import File from howl.io
import config, signal from howl
import style, colors, highlight from howl.ui
import PropertyTable, Sandbox, SandboxedLoader from howl.aux
aullar_config = require 'aullar.config'

css_provider = Gtk.CssProvider!
screen = Gdk.Screen\get_default!
Gtk.StyleContext.add_provider_for_screen screen, css_provider, 600

css_template = [[
.transparent_bg {
  background: rgba(0,0,0,0);
}

.scrollbar.trough {
    background: rgba(0,0,0,0);
}

.header {
  color: ${header_color};
  font: ${header_font};
}

.footer {
  color: ${footer_color};
  font: ${footer_font};
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
background_color_widgets = setmetatable {}, __mode: 'k'

interpolate = (content, values) ->
  content\gsub '%${([%a_]+)}', values

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
  status = theme.window.status
  editor = theme.editor
  hdr = editor.header
  footer = editor.footer
  indicators = editor.indicators
  values =
    status_font: parse_font status.font
    status_color: status.color
    header_color: hdr.color
    header_font: parse_font hdr.font
    footer_color: footer.color
    footer_font: parse_font footer.font
  css = interpolate css_template, values
  css ..= indicators_css indicators
  css ..= status_css status
  css

load_theme = (file) ->
  chunk = loadfile(file.path)
  box = SandboxedLoader file.parent, 'theme', env: colors, no_implicit_globals: true
  box\put :highlight, :flair
  box chunk

apply_theme = ->
  css = theme_css current_theme, current_theme_file
  status = css_provider\load_from_data css
  error 'Error applying theme "' .. current_theme.name .. '"' if not status
  style.set_for_theme current_theme
  highlight.set_for_theme current_theme
  flair.define name, def for name, def in pairs(current_theme.flairs or {})

  if current_theme.editor.gutter
    aullar_config.gutter_styling = current_theme.editor.gutter

  signal.emit 'theme-changed', theme: current_theme

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
    default: 'Liberation Mono, Monaco'
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

config.watch 'font', (name, value) ->
  aullar_config.view_font_name = value
  apply_theme! if current_theme

config.watch 'font_size', (name, value) ->
  aullar_config.view_font_size = value
  apply_theme! if current_theme

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
}
