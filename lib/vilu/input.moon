import keyval_name, keyval_to_unicode from lgi.Gdk
import unichar_to_utf8 from lgi.GLib
bytes = require 'bytes'

_G = _G
t_append = table.insert
t_concat = table.concat
tostring, pcall = tostring, pcall

_ENV = {}
setfenv(1, _ENV) if setfenv

cbuf = bytes.new(6)

export translate_key = (event) ->
  translations = {}

  state = event.state
  modifiers = {}
  t_append modifiers, 'ctrl' if state.CONTROL_MASK
  t_append modifiers, 'shift' if state.SHIFT_MASK
  t_append modifiers, 'alt' if state.MOD1_MASK
  t_append modifiers, ''
  mod_string = t_concat modifiers, '+'

  code = event.keyval
  key_name = keyval_name code
  unicode_char = keyval_to_unicode code

  if unicode_char > 0
    len = unichar_to_utf8(unicode_char, cbuf)
    if len > 0
      utf8 = tostring(cbuf)\sub(1, len)
      t_append translations, utf8
  else
    key_name = key_name\lower! if key_name

  t_append translations, key_name if key_name
  t_append translations, tostring(code)
  [mod_string .. t for t in *translations]

find_handlers = (buffer, translations) ->
  maps = { buffer.keymap, buffer.mode.keymap, keymap }
  handlers = {}
  for map in *maps
    if map
      for t in *translations
        handler = map[t]
        if handler
          t_append handlers, handler
          break
  handlers

export process = (buffer, event) ->
  translations = translate_key event
  handlers = find_handlers buffer, translations
  for handler in *handlers
    status, ret = pcall handler, buffer
    return true if not status or (status and ret)

export keymap = {}

return _ENV
