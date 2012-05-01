import File from vilu.fs
import moon from _G
import error, type, print, loadfile, pairs from _G

_G = _G

_ENV = {}
setfenv(1, _ENV) if setfenv

export available = {}
export current = nil

export load = (theme) ->
  if moon.type(theme) == File
    theme = theme.path

  if type(theme) == 'string'
    theme = loadfile(theme)!

  error '.name not specified for theme' if not theme.name
  available[theme.name] = theme

return _ENV
