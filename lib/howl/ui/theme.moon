-- Copyright 2012-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
Gdk = require 'ljglibs.gdk'
Pango = require 'ljglibs.pango'
require 'ljglibs.gtk.widget'
flair = require 'aullar.flair'
RGBA = Gdk.RGBA
{string: ffi_string, :cast} = require('ffi')

{:config, :signal} = howl
{:style} = howl.ui
{:File} = howl.io
{:PropertyTable} = howl.util
aullar_config = require 'aullar.config'
aullar_styles = require 'aullar.styles'

local loading_css

css_provider = Gtk.CssProvider!
css_provider\connect 'parsing_error', (provider, section, err)->
  err = cast 'GError *', err
  section = cast 'GtkCssSection *', section
  err_s = ffi_string err.message
  at = tonumber section.start_location.bytes
  leading = loading_css\sub math.max(at - 50, 0), at
  trailing = loading_css\sub at + 1, at + 50
  context = leading .. '<ERROR>' .. trailing
  -- logged rather than raised, which would wrap it in the callback's own error message
  log.error "Theme error: #{err_s} at\n\"#{context}\""

display = Gdk.Display\get_default!
Gtk.StyleContext.add_provider_for_display display, css_provider, 7000

base_css = [[
/* Base settings */

window {
  font-size: ${font_size}pt;
  font-family: ${font};
}

popover {
  padding: 0px;
  background-color: #00000000;
  border-radius: 0;
  font-size: ${font_size}pt;
  font-family: ${font};
}

popover arrow {
  background: red;
}

/* Popups opened by an explicit action stand out more than those that appear
   while typing, such as completions */
popover.action-popup contents {
  padding: 4px 6px;
  border-width: 2px;
  border-radius: 6px;
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

.indicator.processes {
  font-weight: bold;
  padding: 0 0.6em;
  margin-right: 1em;
  border-radius: 1em;
  border: 1px solid alpha(currentColor, 0.5);
  background-color: alpha(currentColor, 0.15);
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

lookup_var = (var, vars) ->
    v = vars[var]
    unless v
      error "Undefined variable '#{var}'"

    var_ref = v\match('var%(%-%-([^)]+)%)')
    if var_ref
      lookup_var var_ref, vars
    else
      v

expand_css_variables = (css) ->
  vars = {}
  -- collect root variables
  css = css\gsub ':root%s*(%b{})', (root_css) ->
    for k, v in root_css\gmatch '%-%-([^:]+):%s*([^;]+)'
      vars[k] = v
    ''

  -- expand root variables
  css = css\gsub 'var%(%-%-([^)]+)%)', (var) ->
    lookup_var var, vars

  css

-- Theme mistakes are logged rather than raised, so the rest of the theme still applies
theme_error = (msg) -> log.error "Theme error: #{msg}"

trim = (s) -> s\match '^%s*(.-)%s*$'

to_hex = (rgba, alpha) ->
  channels = { rgba.red, rgba.green, rgba.blue, alpha }
  '#' .. table.concat ['%02x'\format(math.floor(c * 255 + 0.5)) for c in *channels]

-- a color for flairs and backgrounds (which Gdk parses), or nil if <value> isn't one
css_color = (value) ->
  col, alpha = value\match '^alpha%s*%((.+),%s*([%d.]+)%s*%)$'
  rgba = RGBA!
  return nil unless rgba\parse(col and trim(col) or value)
  alpha and to_hex(rgba, tonumber alpha) or value

-- text is drawn by Pango, which takes neither transparency nor every CSS color syntax
text_color = (value) ->
  color = css_color value
  return nil, "invalid color '#{value}'" unless color
  rgba = RGBA color
  return nil, "text colors can't be transparent ('#{value}')" unless rgba\is_opaque!
  pcall(Pango.Color, color) and color or to_hex(rgba)

-- a number, optionally given in px
pixels = (value) -> tonumber(value\match('^(.-)px$') or value)

color_property = (field) -> (def, value) ->
  def[field] = css_color value
  "invalid color '#{value}'" unless def[field]

text_color_property = (field) -> (def, value) ->
  color, err = text_color value
  def[field] = color
  err

-- each sets the property on the definition, and returns an error message if invalid
style_properties = {
  color: text_color_property 'color'
  'background-color': color_property 'background'

  'font-style': (def, value) ->
    return "invalid font-style '#{value}'" unless value == 'italic' or value == 'normal'
    def.font.italic = value == 'italic' or nil

  'font-weight': (def, value) ->
    return "invalid font-weight '#{value}'" unless value == 'bold' or value == 'normal'
    def.font.bold = value == 'bold' or nil

  'font-size': (def, value) ->
    size = tonumber(value\match('^(.-)pt$') or value) or value
    return "invalid font-size '#{value}'" unless aullar_styles.is_font_size size
    def.font.size = size

  'font-family': (def, value) ->
    families = [f\match("^%s*['\"]?(.-)['\"]?%s*$") for f in value\gmatch '[^,]+']
    def.font.family = table.concat families, ','

  'text-decoration': (def, value) ->
    for token in value\gmatch '%S+'
      unless token == 'underline' or token == 'line-through' or token == 'none'
        return "invalid text-decoration '#{value}'"

    def.underline = value\find('underline', 1, true) != nil
    def.strike_through = value\find('line-through', 1, true) != nil
}

flair_shapes = {
  rectangle: flair.RECTANGLE,
  rounded_rectangle: flair.ROUNDED_RECTANGLE,
  sandwich: flair.SANDWICH,
  underline: flair.UNDERLINE,
  wavy_underline: flair.WAVY_UNDERLINE,
  pipe: flair.PIPE,
  strike_through: flair.STRIKE_TROUGH,
}

flair_properties = {
  shape: (def, value) ->
    def.type = flair_shapes[value\gsub('-', '_')]
    "invalid shape '#{value}'" unless def.type

  'border-color': color_property 'foreground'
  'background-color': color_property 'background'
  color: text_color_property 'text_color'

  'border-style': (def, value) ->
    return "invalid border-style '#{value}'" unless value == 'solid' or value == 'dotted' or value == 'dashed'
    def.line_type = value

  'border-radius': (def, value) ->
    def.corner_radius = pixels value
    "invalid border-radius '#{value}'" unless def.corner_radius

  width: (def, value) ->
    def.line_width = pixels value
    "invalid width '#{value}'" unless def.line_width

  height: (def, value) ->
    def.height = value == 'text' and value or pixels value
    "invalid height '#{value}'" unless def.height

  'minimum-width': (def, value) ->
    def.min_width = value == 'letter' and value or pixels value
    "invalid minimum-width '#{value}'" unless def.min_width
}

-- Extracts the "<kind>.<name> { .. }" rules from <css>, returning the definitions by
-- name (with any dashes in it as underscores), along with <css> minus the rules
extract_rules = (css, kind, properties, new_def) ->
  defs, rules = {}, {}
  css = css\gsub "%f[%w_%-%.]#{kind}%.([%w_-]+)%s*(%b{})", (name, body) ->
    rule = "#{kind}.#{name}"
    name = name\gsub '-', '_'
    def = defs[name] or new_def!

    for decl in body\sub(2, -2)\gmatch '[^;]+'
      continue unless decl\find '%S'
      prop, value = decl\match '^%s*([%w-]+)%s*:%s*(.-)%s*$'
      if prop and #value > 0 and not value\find ':'
        handler = properties[prop]
        err = if handler then handler(def, value) else "unknown property '#{prop}'"
        theme_error "#{rule}: #{err}" if err
      else
        theme_error "#{rule}: invalid declaration '#{trim(decl)\gsub('%s+', ' ')}'"

    defs[name] = def
    rules[name] = rule
    ''

  defs, css, rules

extract_css_styles = (css) ->
  extract_rules css, 'style', style_properties, -> font: {}

extract_css_flairs = (css) ->
  flairs, css, rules = extract_rules css, 'flair', flair_properties, -> {}
  for name, def in pairs flairs
    unless def.type
      theme_error "#{rules[name]}: no valid shape, ignoring it"
      flairs[name] = nil

  flairs, css

-- Drops style and flair rules with selectors that extract_rules doesn't take. Gtk would
-- read them as element selectors that silently match nothing.
drop_unsupported_selectors = (css) ->
  css\gsub '([^{}]*)(%b{})', (selector) ->
    selector = trim(selector)\gsub '%s+', ' '
    return if selector\match('^style%.[%w_-]+$') or selector\match('^flair%.[%w_-]+$')
    if selector\find('%f[%w_%-%.]style%.') or selector\find('%f[%w_%-%.]flair%.')
      theme_error "unsupported selector '#{selector}', ignoring the rule: style and flair rules take a single name"
      ''

extract_css_custom = (css) ->
  values = {}
  for decls in css\gmatch '%.gutter%s*{([^}]+)}'
    color = decls\match('%s+color%s*:%s*([^;]-)%s*;')
    values.gutter_color = css_color(color) if color

  values, css

apply_aullar_options = (theme) ->
  -- nil resets it to the default
  aullar_config.gutter_color = theme.custom.gutter_color

apply_theme = ->
  theme = current_theme
  content = expand_css_functions theme.css_file

  -- strip away comments
  content = content\gsub('/%*.-%*/', '')

  content = expand_css_variables content
  content = drop_unsupported_selectors content
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
  flair.set_theme current_theme.flairs
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
