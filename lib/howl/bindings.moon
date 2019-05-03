-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

_G = _G
import table, coroutine, pairs from _G
import pcall, callable, setmetatable, typeof, tostring from _G
import signal, command, sys from howl
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
  kp_home: 'home'
  kp_end: 'end'
  kp_insert: 'insert'
  kp_delete: 'delete'
  kp_enter: { 'return', 'enter' }
  iso_left_tab: 'tab'
  return: 'enter'
  enter: 'return'
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
  kp_prior: 'kp_page_up'
  kp_next: 'kp_page_down'
}

substitute_keyname = (event) ->
  key_name = substituted_names[event.key_name]
  return event unless key_name
  copy = {k,v for k,v in pairs event}
  copy.key_name = key_name
  copy

export action_for = (tr, source='editor') ->
  os = sys.info.os
  empty = {}

  for i = #keymaps, 1, -1
    km = keymaps[i]
    continue unless km
    source_km = km[source] or empty
    os_map = km.for_os and km.for_os[os] or empty
    os_source_map = os_map[source] or empty
    handler = os_source_map[tr] or os_map[tr] or source_km[tr] or km[tr]
    return handler if handler
  nil

find_handlers = (event, source, translations, maps_to_search, ...) ->
  handlers = {}
  empty = {}
  os = sys.info.os

  for map in *maps_to_search
    continue unless map

    source_map = map[source] or empty
    handler = nil

    map_binding_for = map.binding_for
    source_map_binding_for = source_map.binding_for
    os_map = map.for_os and map.for_os[os] or empty
    os_source_map = os_map[source] or empty

    for t in *translations
      handler = os_source_map[t] or source_map[t] or os_map[t] or map[t]
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

export cancel_capture = ->
  capture_handler = nil
  is_capturing = false

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
  meta = (event.meta and 'meta_') or ''
  event = substitute_keyname event
  alternate = alternate_names[event.key_name]

  translations = {}
  character = event.character
  if event.lock and character
    if event.shift
      character = character.uupper
    else
      character = character.ulower

  append translations, ctrl .. meta .. alt .. character if character
  modifiers = ctrl .. meta .. shift .. alt

  if event.key_name and event.key_name != character
    append translations, modifiers .. event.key_name

  if typeof(alternate) == 'table'
    for a in *alternate
      append translations, modifiers .. a
  elseif alternate
    append translations, modifiers .. alternate
  append translations, modifiers .. event.key_code

  translations

export dispatch = (event, source, maps_to_search, ...) ->
  event = substitute_keyname event
  translations = translate_key event
  handlers, halt_map, map_opts = find_handlers event, source, translations, maps_to_search, ...
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

export can_dispatch = (event, source, maps_to_search) ->
  event = substitute_keyname event
  translations = translate_key event
  handlers = find_handlers event, source, translations, maps_to_search
  return #handlers > 0

export process = (event, source, extra_keymaps = {},  ...) ->
  event = substitute_keyname event
  translations = translate_key event
  return true if process_capture event, source, translations, ...
  emit_result = signal.emit 'key-press', :event, :source, :translations, parameters: {...}
  return true if emit_result == signal.abort

  maps = {}
  append maps, map for map in *extra_keymaps
  for i = #keymaps, 1, -1
    append maps, keymaps[i]

  dispatch event, source, maps, ...

export capture = (handler) ->
  capture_handler = handler
  is_capturing = true

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

return _ENV
