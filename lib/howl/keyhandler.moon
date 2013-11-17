_G = _G
import tostring, pcall, callable, type, append, print from _G
import signal, command from howl

signal.register 'key-press',
  description: [[Signaled whenever a key is pressed.

If any handler returns true, the key press is considered to be handled, and any subsequent
processing is skipped.
]]
  parameters:
    event: 'The event for the key press'
    translations: 'A list of readable translations for the key event'
    source: 'The source of the key press (e.g. "editor")'
    parameters: 'Other source specific parameters (e.g. an editor for source = "editor")'

_ENV = {}
setfenv(1, _ENV) if setfenv

capture_handler = nil

alternate_names = {
  kp_up: 'up'
  kp_down: 'down'
  kp_left: 'left'
  kp_right: 'right'
  kp_page_up: 'page_up'
  kp_page_down: 'page_down'
  iso_left_tab: 'tab'
  return: 'enter'
}

alternate_translation = (event) ->
  name = event.key_name
  return alternate_names[name] if name

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

find_handlers = (event, source, translations, keymaps, ...) ->
  handlers = {}
  for map in *keymaps
    if map
      for target_map in *{ map[source], map }
        continue unless target_map

        handler = nil
        for t in *translations
          handler = target_map[t]
          break if handler

        if not handler and callable target_map.on_unhandled
          handler = target_map.on_unhandled event, source, translations, ...

        if handler
          append handlers, handler
          break

  handlers

process_capture = (event, source, translations, ...) ->
  if capture_handler
    status, ret = pcall capture_handler, event, source, translations, ...
    if not status or ret != false
      capture_handler = nil

    _G.log.error ret unless status

    return true

export dispatch = (event, source, keymaps, ...) ->
  translations = translate_key event
  handlers = find_handlers event, source, translations, keymaps, ...

  for handler in *handlers
    status, ret = true, true
    if type(handler) == 'string'
      status, ret = pcall command.run, handler
    else
      status, ret = pcall handler, ...

    _G.log.error ret unless status

    return true if not status or (status and ret != false)

  false

export process = (event, source, extra_keymaps,  ...) ->
  translations = translate_key event
  return true if process_capture event, source, translations, ...
  return true if signal.emit 'key-press', :event, :source, :translations, parameters: {...}

  maps = {}
  append maps, map for map in *(extra_keymaps or {})
  append maps, keymap

  dispatch event, source, maps, ...

export capture = (handler) ->
  capture_handler = handler

export cancel_capture = ->
  capture_handler = nil

export keymap = {}

return _ENV
