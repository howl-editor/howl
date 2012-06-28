state = bundle_load 'state.moon'
import apply from state
_G = _G
import tonumber from _G

cursor_home = (editor) -> apply editor, -> editor.cursor\home!

map = {}
setfenv 1, map

export *

j = (editor) -> apply editor, -> editor.cursor\down!
k = (editor) -> apply editor, -> editor.cursor\up!
h = (editor) -> apply editor, -> editor.cursor\left!
l = (editor) -> apply editor, -> editor.cursor\right!
e = (editor) -> apply editor, -> editor.cursor\word_right_end!
w = (editor) -> apply editor, -> editor.cursor\word_right!
b = (editor) -> apply editor, -> editor.cursor\word_left!
G = (editor) -> apply editor, -> editor.cursor\eof!
map['$'] = (editor) -> apply editor, -> editor.cursor\line_end!

on_unhandled = (event) ->
  char = event.character
  if char
    if char\match '^%d$'
      -- we need to special case '0' here as that's a valid command in its own
      -- right, unless it's part of a numerical prefix
      if char == '0' and not state.count then return cursor_home
      else state.add_number tonumber char
    elseif char\match '^%w$'
      state.reset!

  -> true

return map
