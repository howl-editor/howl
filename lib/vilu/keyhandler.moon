_G = _G
import tostring, pcall, callable from _G
import signal from vilu
t_append, t_concat = table.insert, table.concat

_ENV = {}
setfenv(1, _ENV) if setfenv

export translate_key = (event) ->
  ctrl = (event.control and 'ctrl+') or ''
  shift = (event.shift and 'shift+') or ''
  alt = (event.alt and 'alt+') or ''

  translations = {}
  t_append translations, ctrl .. alt .. event.character if event.character
  t_append translations, ctrl .. shift .. alt .. event.key_name if event.key_name
  t_append translations, ctrl .. shift .. alt .. event.key_code
  translations

find_handlers = (translations, event, keymaps) ->
  handlers = {}
  for map in *keymaps
    if map
      handler = nil
      for t in *translations
        handler = map[t]
        break if handler

      if not handler and callable map.on_unhandled
        handler = map.on_unhandled event, translations

      t_append handlers, handler if handler

  handlers

export dispatch = (event, keymaps, ...) ->
  translations = translate_key event
  handlers = find_handlers translations, event, keymaps
  for handler in *handlers
    status, ret = pcall handler, ...

    if not status
      signal.emit 'error', 'Error invoking key handler: ' .. ret

    return true if not status or (status and ret != false)

  false

export process = (editor, event) ->
  translations = translate_key event
  buffer = editor.buffer
  maps = { buffer.keymap, buffer.mode and buffer.mode.keymap, keymap }

  return true if signal.emit 'key-press', event
  dispatch event, maps, editor

export keymap = {}

return _ENV
