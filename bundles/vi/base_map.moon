state = bundle_load 'state.moon'
import apply from state
import keyhandler from lunar
import math, tonumber, print, _G from _G

default_map = keyhandler.keymap

cursor_home = (editor) -> apply editor, (editor) -> editor.cursor\home!

forward_to_char = (event, translations, editor) ->
  if event.character
    apply editor, (editor) -> editor\forward_to_match event.character
  else
    return false

back_to_char = (event, translations, editor) ->
  if event.character
    apply editor, (editor) -> editor\backward_to_match event.character
  else
    return false

map = {}
setfenv 1, map

export *

cursor_properties = style: 'block'

j = (editor) -> apply editor, (editor) -> editor.cursor\down!
k = (editor) -> apply editor, (editor) -> editor.cursor\up!
h = (editor) -> apply editor, (editor) -> editor.cursor\left!
l = (editor) -> apply editor, (editor) -> editor.cursor\right!

e = (editor) -> apply editor, (editor) ->
  with editor.cursor
    current_pos = .pos
    \word_right_end!
    \word_right_end! if .pos == current_pos + 1
    \left!

w = (editor) -> apply editor, (editor, _state) ->
  if _state.change
    editor.cursor\word_right_end!
  else
    editor.cursor\word_right!

b = (editor) -> apply editor, (editor) -> editor.cursor\word_left!

g = (editor) ->
  if state.go
    editor.cursor\start!
    state.reset!
  else
    state.go = true

G = (editor) ->
  if state.count then editor.cursor.line = state.count
  else editor.cursor\eof!
  state.reset!

f = (editor) -> keyhandler.capture forward_to_char
F = (editor) -> keyhandler.capture back_to_char
map['/'] = 'search-forward'
n = 'repeat-search'

map['$'] = (editor) -> apply editor, (editor) ->
  editor.cursor.column = math.max(1, #editor.current_line)

on_unhandled = (event) ->
  char = event.character
  modifiers = event.control or event.alt
  if char and not modifiers
    if char\match '^%d$'
      -- we need to special case '0' here as that's a valid command in its own
      -- right, unless it's part of a numerical prefix
      if char == '0' and not state.count then return cursor_home
      else state.add_number tonumber char
    elseif char\match '^%w$'
      state.reset!

    return -> true

  (editor) -> keyhandler.dispatch event, { default_map }, editor

return map
