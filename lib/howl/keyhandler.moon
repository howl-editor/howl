_G = _G
import tostring, pcall, callable, type, append, print from _G
import signal, command from howl

signal.register 'key-press',
  description: [[Signaled whenever a key is pressed.

If any handler returns true, the key press is considered to be handled, and any subsequent
processing is skipped.
]]
  parameters:
    editor: 'The editor for which the key press occured'
    event: 'The event for the key press'
    translations: 'A list of readable translations for the key event'

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
    return: 'enter'
  }
  name = event.key_name
  return alternate_names[name] if name

capture_handler = nil

export translate_key = (event) ->
  ctrl = (event.control and 'ctrl_') or ''
  shift = (event.shift and 'shift_') or ''
  alt = (event.alt and 'alt_') or ''
  alternate = alternate_translation event

  translations = {}
  append translations, ctrl .. alt .. event.character if event.character

  if event.key_name and event.key_name != event.character
    append translations, ctrl .. shift .. alt .. event.key_name

  append translations, ctrl .. shift .. alt .. alternate if alternate
  append translations, ctrl .. shift .. alt .. event.key_code
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

process_capture = (event, translations, ...) ->
  if capture_handler
    status, ret = pcall capture_handler, event, translations, ...
    if not status or ret != false
      capture_handler = nil

    _G.log.error ret unless status

    return true

export dispatch = (event, keymaps, ...) ->
  translations = translate_key event
  handlers = find_handlers translations, event, keymaps

  for handler in *handlers
    status, ret = true, true
    if type(handler) == 'string'
      status, ret = pcall command.run, handler
    else
      status, ret = pcall handler, ...

    _G.log.error ret unless status

    return true if not status or (status and ret != false)

  false

export process = (editor, event) ->
  translations = translate_key event
  buffer = editor.buffer
  maps = { buffer.keymap, buffer.mode and buffer.mode.keymap, keymap }

  return true if process_capture event, translations, editor
  return true if signal.emit 'key-press', :event, :translations, :editor

  dispatch event, maps, editor

export capture = (handler) ->
  capture_handler = handler

export cancel_capture = ->
  capture_handler = nil

export keymap = {}

return _ENV
