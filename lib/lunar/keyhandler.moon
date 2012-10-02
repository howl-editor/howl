_G = _G
import tostring, pcall, callable, type, append from _G
import signal, command from lunar

_ENV = {}
setfenv(1, _ENV) if setfenv

alternate_translation = (event) ->
  alternate_names = {
    kp_up: 'up'
    kp_down: 'down'
    kp_left: 'left'
    kp_right: 'right'
    kp_page_up: 'page_up'
    kp_page_down: 'page_down'
    iso_left_tab: 'shift_tab'
  }
  name = event.key_name
  return alternate_names[name] if name

export translate_key = (event) ->
  ctrl = (event.control and 'ctrl_') or ''
  shift = (event.shift and 'shift_') or ''
  alt = (event.alt and 'alt_') or ''
  alternate = alternate_translation event

  translations = {}
  append translations, ctrl .. alt .. event.character if event.character
  append translations, ctrl .. shift .. alt .. event.key_name if event.key_name
  append translations, ctrl .. shift .. alt .. event.key_code
  append translations, alternate if alternate
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

      append handlers, handler if handler

  handlers

export dispatch = (event, keymaps, ...) ->
  translations = translate_key event
  handlers = find_handlers translations, event, keymaps
  for handler in *handlers
    status, ret = true, true
    if type(handler) == 'string'
      status, ret = pcall, command.run handler
    else
      status, ret = pcall handler, ...

    if not status
      _G.log.error ret

    return true if not status or (status and ret != false)

  false

export process = (editor, event) ->
  buffer = editor.buffer
  maps = { buffer.keymap, buffer.mode and buffer.mode.keymap, keymap }

  return true if signal.emit 'key-press', event
  dispatch event, maps, editor

export keymap = {}

return _ENV
