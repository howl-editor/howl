-- Copyright 2012-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
Gdk = require 'ljglibs.gdk'
require 'ljglibs.gtk.widget'
flair = require 'aullar.flair'
RGBA = Gdk.RGBA
{string: ffi_string, :cast} = require('ffi')

import config, signal from howl
import style, colors from howl.ui
{:File} = howl.io
import PropertyTable from howl.util
aullar_config = require 'aullar.config'

local loading_css

css_provider = Gtk.CssProvider!
css_provider\on_parsing_error (provider, section, err)->
  err = cast 'GError *', err
  section = cast 'GtkCssSection *', section
  err_s = ffi_string err.message
  at = tonumber section.start_location.bytes
  leading = loading_css\sub math.max(at - 50, 0), at
  trailing = loading_css\sub at + 1, at + 50
  context = leading .. '<ERROR>' .. trailing
  error "Theme error: #{err_s} at\n\"#{context}\""

display = Gdk.Display\get_default!
Gtk.StyleContext.add_provider_for_display display, css_provider, 7000

base_css = [[
window {
  padding: 0.4em;
  font-size: ${font_size}pt;
  font-family: ${font};
}

scrollbar {
  background-color: #00000000;
}

.gutter {
  padding-left: 0.5em;
  padding-right: 0.5em;
}

.content-box > .header {
  padding: 5px;
}

.content-box > .footer {
  padding: 5px;
}

window.test-window {
  background: transparent;
}

/* Begin theme below */
]]

theme_files = {}
current_theme = nil
theme_active = false

interpolate = (content, values) ->
  content\gsub '%${([%a_]+)}', values

expand_css_functions = (css_file) ->
  css_file = File(css_file)
  base_dir = css_file.parent
  content = css_file.contents
  content = content\gsub "theme%-url%s*%(['\"](.-)['\"]%s*%)", (rel) ->
    path = base_dir\join(rel)
    "url(\"file://#{path}\")"
  content

expand_css_variables = (css) ->
  vars = {}
  -- collect root variables
  css = css\gsub ':root%s*(%b{})', (root_css) ->
    for k, v in root_css\gmatch '%-%-([^:]+):%s*([^;]+)'
      vars[k] = v
    ''

  -- expand root variables
  css = css\gsub 'var%(%-%-([^)]+)%)', (var) ->
    v = vars[var]
    unless v
      print "Undefined variable '#{var}'"
      var
    v

  css

css_color = (decl) ->
  return nil unless decl and #decl > 0
  col, alpha = decl\match('%s*alpha%s*%(([^,%s]+)%s*,%s*([%d.]+)%)')
  if col
    rgba = RGBA(colors[col] or col)
    '#%02x%02x%02x%02x'\format(
      (rgba.red * 255),
      (rgba.green * 255),
      (rgba.blue * 255),
      (tonumber(alpha) * 255)
    )
  else
    decl

extract_css_styles = (css) ->
  styles = {}
  css = css\gsub 'style%.([%w-]+)%s*%{([^}]+)}', (name, decls) ->
    name = name\gsub '-', '_'
    font = {}
    style_def = styles[name] or { :font }

    -- get individual declarations
    vars = {var\gsub('-', '_'), val for var, val in decls\gmatch '(%S+)%s*:%s*([^;]+);'}
    font.italic = true if vars.font_style == 'italic'
    font.bold = true if vars.font_weight == 'bold'
    font.size = vars.font_size
    font.family = vars.font_family
    style_def.color = css_color vars.color
    style_def.background = css_color vars.background_color
    if vars.text_decoration
      style_def.underline = vars.text_decoration\find('underline') != nil
      style_def.strike_through = vars.text_decoration\find('line%-through') != nil

    styles[name] = style_def
    ''

  styles, css

extract_css_flairs = (css) ->
  TYPES = {
    rectangle: flair.RECTANGLE,
    rounded_rectangle: flair.ROUNDED_RECTANGLE,
    sandwich: flair.SANDWICH,
    underline: flair.UNDERLINE,
    wavy_underline: flair.WAVY_UNDERLINE,
    pipe: flair.PIPE,
    strike_through: flair.STRIKE_TROUGH,
  }
  flairs = {}
  css = css\gsub 'flair%.([%w-]+)%s*%{([^}]+)}', (name, decls) ->
    name = name\gsub '-', '_'
    flair_def = flairs[name] or {}

    -- get individual declarations
    vars = {var\gsub('-', '_'), val for var, val in decls\gmatch '(%S+)%s*:%s*([^;]+);'}
    flair_def.foreground = css_color vars.border_color
    type = vars.shape and vars.shape\gsub('-', '_')
    unless type
      error "No shape specified for flar '#{name}': #{decls}"
    flair_def.type = TYPES[type]

    if vars.width
      flair_def.line_width = tonumber((vars.width\gsub('px', '')))

    flair_def.text_color = css_color vars.color
    flair_def.background = css_color vars.background_color
    flair_def.height = vars.height
    if vars.minimum_width
      flair_def.min_width = tonumber(vars.minimum_width) or vars.minimum_width or flair_def.min_width

    flairs[name] = flair_def
    ''

  flairs, css

extract_css_custom = (css) ->
  values = {}
  for decls in css\gmatch '%.gutter%s*{([^}]+)}'
    moon.p decls
    color = decls\match('%s+color%s*:%s*([^;]+);')
    values.gutter_color = css_color(color) if color

  values, css

apply_aullar_options = (theme) ->
  custom = theme.custom
  return unless custom
  if custom.gutter_color
    aullar_config.gutter_color = custom.gutter_color

apply_theme = ->
  theme = current_theme
  content = expand_css_functions theme.css_file

  -- strip away comments
  content = content\gsub('/%*.-%*/', '')

  content = expand_css_variables content
  theme.styles, content = extract_css_styles content
  theme.flairs, content = extract_css_flairs content
  theme.custom, content = extract_css_custom content
  base_values =
    font_size: config.font_size
    font: "#{config.font},monospace"

  base = interpolate base_css, base_values
  css = base .. content
  loading_css = css
  css_provider\load_from_data css
  loading_css = nil
  style.set_for_theme theme
  flair.define name, def for name, def in pairs(current_theme.flairs or {})
  apply_aullar_options current_theme

  signal.emit 'theme-changed', theme: current_theme

set_theme = (name) ->
  if name == nil
    current_theme = nil
    theme_active = false
    return

  file = theme_files[name]
  error 'No theme found with name "' .. name .. '"' if not file

  theme = {
    css_file: file
  }

  theme.name = name
  current_theme = theme
  if theme_active
    apply_theme!

with config
  .define
    name: 'theme'
    description: 'The theme to use (colors, styles, highlights, etc.)'
    default: 'Monokai'
    type_of: 'string'
    options: -> [name for name in pairs theme_files]
    scope: 'global'

  .define
    name: 'font'
    description: 'The main font used within the application'
    -- default: 'Liberation Mono, Monaco'
    default: 'monospace'
    type_of: 'string'
    scope: 'global'

  .define
    name: 'font_size'
    description: 'The size of the main font'
    default: aullar_config.view_font_size
    type_of: 'number'
    scope: 'global'

config.watch 'theme', (_, name) ->
  set_theme name

config.watch 'font', (name, value) ->
  apply_theme! if current_theme

config.watch 'font_size', (name, value) ->
  apply_theme! if current_theme

signal.register 'theme-changed',
  description: 'Signaled right after a theme has been applied'
  parameters:
    theme: 'The theme that has been set'

return PropertyTable {
  current: get: -> current_theme

  :css_provider

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
