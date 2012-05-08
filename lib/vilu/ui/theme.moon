import File from vilu.fs
import style from vilu.ui
import moon from _G
import error, type, print, loadfile, pairs, setmetatable, rawset from _G

_G = _G

_ENV = {}
setfenv(1, _ENV) if setfenv

export available = {}
current_theme = nil

set_theme = (theme) ->
  current_theme = theme
  style.set_for_theme theme

export load = (theme) ->
  if moon.type(theme) == File
    theme = theme.path

  if type(theme) == 'string'
    theme = loadfile(theme)!

  error '.name not specified for theme' if not theme.name
  available[theme.name] = theme

setmetatable _ENV,
  __newindex: (t, k, v)->
    if k == 'current' then set_theme v
    else rawset t, k, v
  __index: (t, k) ->
    if k == 'current' then current_theme

return _ENV
