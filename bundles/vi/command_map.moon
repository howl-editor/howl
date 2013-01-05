state = ...
base_map = bundle_load 'base_map.moon'
import apply, record, repeat_last from state
import command, keyhandler from howl
import _G, math, tostring from _G

map = setmetatable {}, __index: base_map
setfenv 1, map

one_right = (editor) ->
  if editor.cursor.at_end_of_line
    editor\insert ' '
  else
    editor.cursor\right!

export *

to_insert = (editor) -> state.change_mode editor, 'insert'

replace_char = (event, translations, editor) ->
  if event.character
    apply editor, ->
      editor.buffer\delete editor.cursor.pos, 1
      editor.buffer\insert event.character, editor.cursor.pos, 1
  else
    return false

name = 'VI'

escape = (editor) ->
  state.reset!

a = (editor) ->
  one_right editor
  to_insert editor

A = (editor) ->
  editor.cursor\line_end!
  to_insert editor

c = (editor) ->
  if state.change then apply editor, ->
    editor\copy_line!
    editor.cursor\home!
    editor\delete_to_end_of_line!
    to_insert editor
  else
    state.change = true

C = (editor) -> apply editor, (editor) ->
  editor\delete_to_end_of_line!
  to_insert editor

d = (editor) ->
  if not state.delete
    state.delete = true
    return

  -- dd
  count = state.count or 1

  record editor, (editor) ->
    current_line = editor.current_line
    lines = editor.buffer.lines
    start_pos = current_line.start_pos
    end_line = lines[current_line.nr + count]
    end_pos = end_line and end_line.start_pos - 1 or #editor.buffer + 1

    with editor.selection
      \set start_pos, end_pos
      \cut!

D = (editor) ->
  if state.has_modifier!
    state.reset!
    return

  apply editor, (editor) -> editor\delete_to_end_of_line!

i = to_insert

J = (editor) -> apply editor, -> editor\join_lines!

o = (editor) -> apply editor, ->
  A editor
  editor\newline_and_format!

O = (editor) -> apply editor, ->
  current_indent = editor.current_line.indentation
  editor.cursor\home!
  editor\newline!
  editor.cursor\up!
  editor.current_line.indentation = current_indent
  editor.cursor.column = current_indent + 1
  to_insert editor

p = (editor) -> apply editor, ->
  one_right editor
  editor\paste!

P = (editor) -> apply editor, -> editor\paste!

r = (editor) ->  keyhandler.capture replace_char

u = 'editor:undo'
ctrl_r = 'editor:redo'

v = (editor) -> state.change_mode editor, 'visual'

x = (editor) -> apply editor, -> editor.buffer\delete editor.cursor.pos, 1

y = (editor) ->
  if state.yank
    apply editor, -> editor\copy_line!
  else
    state.yank = true

Y = (editor) -> editor\copy_line!

map['.'] = (editor) -> repeat_last editor
map[':'] = (editor) -> command.run!

return map
