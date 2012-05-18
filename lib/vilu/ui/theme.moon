import Gdk, Gtk from lgi
import File from vilu.fs
import style from vilu.ui
import moon from _G
import error, type, print, loadfile, pairs, setmetatable, rawset from _G
_G = _G

css_provider = Gtk.CssProvider\get_default!
screen = Gdk.Screen\get_default!
Gtk.StyleContext.add_provider_for_screen screen, css_provider, 600

css_template = [[
GtkWindow {
  ${window_background};
}

.view {
  border-width: 1px 3px 3px 1px;
  background-color: ${view_border_color};
}

.header_box {
  background-color: ${header_border_color};
}

.view .header {
  ${header_background};
  border-width: 0px;
}

.view .header .title {
  color: ${title_color};
  font: ${title_font};
}
]]

_ENV = {}
setfenv(1, _ENV) if setfenv

export available = {}
current_theme = nil

parse_background = (value, theme_dir) ->
  true
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

theme_css = (theme) ->
  t = theme.theme
  dir = theme.file.parent
  hdr = t.view.header
  tv_title = hdr.title
  values =
    window_background: parse_background(t.window.background, dir)
    view_border_color: t.view.border_color
    header_background: parse_background(hdr.background, dir)
    header_border_color: hdr.border_color
    title_color: tv_title.color
    title_font: parse_font(tv_title.font)
  css_template\gsub '%${([%a_]+)}', values

set_theme = (theme) ->
  css = theme_css theme
  status = css_provider\load_from_data css
  error 'Error loading theme' if not status
  current_theme = theme
  style.set_for_theme theme.theme

export load = (file) ->
  theme = loadfile(file.path)!

  error '.name not specified for theme' if not theme.name
  available[theme.name] = :theme, file: file

setmetatable _ENV,
  __newindex: (t, k, v)->
    if k == 'current' then set_theme v
    else rawset t, k, v
  __index: (t, k) ->
    if k == 'current' then current_theme

return _ENV
