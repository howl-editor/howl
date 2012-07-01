import Gdk, Gtk from lgi
import File from vilu.fs
import style, colors from vilu.ui
import PropertyTable, Sandbox from vilu.aux

css_provider = Gtk.CssProvider\get_default!
screen = Gdk.Screen\get_default!
Gtk.StyleContext.add_provider_for_screen screen, css_provider, 600

css_template = [[
GtkWindow {
  ${window_background};
}

.editor {
  border-width: 1px 3px 3px 1px;
  background-color: ${editor_border_color};
}

.sci_box {
  background-color: ${editor_divider_color};
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

available = {}
theme_files = {}
current_theme = nil

interpolate = (content, values) ->
  content\gsub '%${([%a_]+)}', values

parse_background = (value, theme_dir) ->
  if value\match '^%s*#%x+%s*$'
    'background-color: ' .. value
  elseif value\find '-gtk-gradient', 1, true
    'background-image: ' .. value
  else
    if not File.is_absolute value
      value = theme_dir\join(value).path
    "background-image: url('" .. value .. "')"

parse_font = (font) ->
  desc = font.name
  desc ..= ' bold' if font.bold
  desc ..= ' italic' if font.italic
  desc ..= ' ' .. font.size if font.size
  desc

indicator_css = (indicators) ->
  css = ''
  for id, def in pairs indicators
    clazz = '.indic_' .. id
    indic_css = clazz .. ' { '
    if def.color then indic_css ..= 'color: ' .. def.color .. '; '
    if def.font then indic_css ..= 'font: ' .. parse_font(def.font).. '; '
    indic_css ..= ' }\n'
    css ..= indic_css
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
  css ..= indicator_css indicators
  css ..= status_css status

load_theme = (file) ->
  chunk = loadfile(file.path)
  box = Sandbox colors
  box chunk

set_theme = (name) ->
  file = theme_files[name]
  error 'No theme found with name "' .. name .. '"' if not file
  theme = load_theme file
  css = theme_css theme, file
  status = css_provider\load_from_data css
  error 'Error loading theme "' .. name .. '"' if not status
  theme.name = name
  current_theme = theme
  style.set_for_theme theme

register = (name, file) ->
  error 'name not specified for theme', 2 if not name
  error 'file not specified for theme', 2 if not file
  available[#available + 1] = name
  theme_files[name] = file

mod = PropertyTable {
  current:
    get: -> current_theme
    set: (_, theme) -> set_theme theme

  available:
    get: -> available
}

mod.register = register

return mod
