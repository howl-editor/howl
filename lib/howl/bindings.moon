-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

_G = _G
import table, coroutine, pairs, io from _G
import tostring, pcall, callable, type, print, setmetatable, typeof from _G
import signal, command from howl
append = table.insert

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
keymap_options = setmetatable {}, __mode: 'k'
export keymaps = {}
export is_capturing = false

alternate_names = {
  kp_up: 'up'
  kp_down: 'down'
  kp_left: 'left'
  kp_right: 'right'
  kp_page_up: 'page_up'
  kp_page_down: 'page_down'
  iso_left_tab: 'tab'
  return: 'enter'
  altL: 'alt'
  altR: 'alt'
  shiftL: 'shift'
  shiftR: 'shift'
  ctrlL: 'ctrl'
  ctrlR: 'ctrl'
  metaL: 'meta'
  metaR: 'meta'
  superL: 'super'
  superR: 'super'
 }

substituted_names = {
  meta_l: 'metaL'
  meta_r: 'metaR'
  alt_l: 'altL'
  alt_r: 'altR'
  shift_l: 'shiftL'
  shift_r: 'shiftR'
  control_l: 'ctrlL'
  control_r: 'ctrlR'
  super_l: 'superL'
  super_r: 'superR'
}

substitute_keyname = (event) ->
  key_name = substituted_names[event.key_name]
  return event unless key_name
  copy = {k,v for k,v in pairs event}
  copy.key_name = key_name
  copy

find_handlers = (event, source, translations, keymaps, ...) ->
  handlers = {}
  for map in *keymaps
    continue unless map
    source_map = map[source] or {}
    handler = nil

    source_map_binding_for = source_map.binding_for
    map_binding_for = map.binding_for

    for t in *translations
      handler = source_map[t] or map[t]
      break if handler

      if source_map_binding_for or map_binding_for
        cmd = action_for t
        if typeof(cmd) == 'string'
          handler = source_map_binding_for and source_map_binding_for[cmd]
          break if handler
          handler = map_binding_for and map_binding_for[cmd]
          break if handler

    if not handler and callable map.on_unhandled
      handler = map.on_unhandled event, source, translations, ...

    append handlers, handler if handler

    opts = keymap_options[map] or {}
    return handlers, map, opts if opts.block or opts.pop

  handlers

process_capture = (event, source, translations, ...) ->
  if capture_handler
    status, ret = pcall capture_handler, event, source, translations, ...
    if not status or ret != false
      cancel_capture!

    _G.log.error ret unless status

    return true

export push = (km, options = {}) ->
  append keymaps, km
  keymap_options[km] = options

export remove = (map) ->
  error "No bindings in stack" unless #keymaps > 0

  for i = 1, #keymaps
    if keymaps[i] == map
      keymap_options[map] = nil
      table.remove keymaps, i
      return true

  false

export pop = ->
  remove keymaps[#keymaps]

export translate_key = (event) ->
  ctrl = (event.control and 'ctrl_') or ''
  shift = (event.shift and 'shift_') or ''
  alt = (event.alt and 'alt_') or ''
  event = substitute_keyname event
  alternate = alternate_names[event.key_name]

  translations = {}
  append translations, ctrl .. alt .. event.character if event.character

  if event.key_name and event.key_name != event.character
    append translations, ctrl .. shift .. alt .. event.key_name

  append translations, ctrl .. shift .. alt .. alternate if alternate
  append translations, ctrl .. shift .. alt .. event.key_code
  translations

export dispatch = (event, source, keymaps, ...) ->
  event = substitute_keyname event
  translations = translate_key event
  handlers, halt_map, map_opts = find_handlers event, source, translations, keymaps, ...
  remove halt_map if halt_map and map_opts.pop

  for handler in *handlers
    status, ret = true, true
    htype = typeof handler

    f = if htype == 'string'
      -> command.run handler
    elseif callable handler
      (...) -> handler ...

    if f
      co = coroutine.create f
      status, ret = coroutine.resume co, ...
    elseif htype == 'table'
      push handler, pop: true
    else
      _G.log.error "Illegal handler: type #{htype}"

    _G.log.error ret unless status
    return true if not status or (status and ret != false)

  false

export process = (event, source, extra_keymaps = {},  ...) ->
  event = substitute_keyname event
  translations = translate_key event
  return true if process_capture event, source, translations, ...
  return true if signal.emit 'key-press', :event, :source, :translations, parameters: {...}

  maps = {}
  append maps, map for map in *extra_keymaps
  for i = #keymaps, 1, -1
    append maps, keymaps[i]

  dispatch event, source, maps, ...

export capture = (handler) ->
  capture_handler = handler
  is_capturing = true

export cancel_capture = ->
  capture_handler = nil
  is_capturing = false

export is_capturing = ->
  capture_handler != nil

export keystrokes_for = (handler, source = nil) ->
  keystrokes = {}
  for i = #keymaps, 1, -1
    km = keymaps[i]
    source_km = km[source]
    if source_km
      for keystroke, h in pairs source_km
        if h == handler
          append keystrokes, keystroke

    for keystroke, h in pairs km
      if h == handler
        append keystrokes, keystroke

  keystrokes

export action_for = (translation, source='editor') ->
  for i = #keymaps, 1, -1
    km = keymaps[i]
    continue unless km
    source_km = km[source] or {}
    handler = source_km[translation] or km[translation]
    return handler if handler
  nil

return _ENV
