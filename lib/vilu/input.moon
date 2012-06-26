_G = _G
import tostring, pcall, callable from _G
import signal from vilu
t_append, t_concat = table.insert, table.concat

_ENV = {}
setfenv(1, _ENV) if setfenv

export translate_key = (args) ->
  ctrl = (args.control and 'ctrl+') or ''
  shift = (args.shift and 'shift+') or ''
  alt = (args.alt and 'alt+') or ''

  translations = {}
  t_append translations, ctrl .. alt .. args.character if args.character
  t_append translations, ctrl .. shift .. alt .. args.key_name if args.key_name
  t_append translations, ctrl .. shift .. alt .. args.key_code
  translations

find_handlers = (buffer, translations) ->
  maps = { buffer.keymap, buffer.mode and buffer.mode.keymap, keymap }
  handlers = {}
  for map in *maps
    if map
      handler = nil
      for t in *translations
        handler = map[t]
        break if handler

      if not handler and callable map.on_unhandled
        handler = map.on_unhandled translations

      t_append handlers, handler if handler

  handlers

export process = (editor, buffer, args) ->
  translations = translate_key args
  handlers = find_handlers buffer, translations
  for handler in *handlers
    status, ret = pcall handler, editor, buffer

    if not status
      signal.emit 'error', 'Error invoking input handler: ' .. ret

    return true if not status or (status and ret != false)

  false

export keymap = {}

return _ENV
