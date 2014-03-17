state = ...
base_map = bundle_load 'base_map'
import apply, record, repeat_last from state
import command, bindings from howl

one_right = (editor) ->
  if editor.cursor.at_end_of_line
    editor\insert ' '
  else
    editor.cursor\right!

to_insert = (editor) ->
  state.change_mode editor, 'insert'
  state.record editor, ->

replace_char = (event, source, translations, editor) ->
  if event.character
    apply editor, (editor) ->
      with editor.cursor
        editor.buffer\delete .pos, .pos
        editor.buffer\insert event.character, .pos, 1
  else
    return false

map = {
  name: 'VI'

  editor: setmetatable {
    escape: (editor) ->
      state.reset!

    a: (editor) ->
      one_right editor
      to_insert editor

    A: (editor) ->
      editor.cursor\line_end!
      to_insert editor

    c: (editor) ->
      if state.change then apply editor, (editor) ->
        editor\copy_line!
        editor.cursor\home!
        editor\delete_to_end_of_line!
        to_insert editor
      else
        state.change = true

    C: (editor) -> apply editor, (editor) ->
      editor\delete_to_end_of_line!
      to_insert editor

    d: (editor) ->
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
        end_pos = end_line and end_line.start_pos or #editor.buffer + 1

        with editor.selection
          .includes_cursor = false
          \set start_pos, end_pos
          \cut!
          .includes_cursor = true

    D: (editor) ->
      if state.has_modifier!
        state.reset!
        return

      apply editor, (editor) -> editor\delete_to_end_of_line!

    i: to_insert

    J: (editor) -> apply editor, (editor) -> editor\join_lines!

    o: (editor) -> apply editor, (editor) ->
      editor.cursor\line_end!
      to_insert editor
      editor\newline!

    O: (editor) -> apply editor, (editor) ->
      editor.cursor\home!
      editor\newline!
      editor.cursor\up!
      editor\indent!
      to_insert editor

    p: (editor) -> apply editor, (editor) ->
      one_right editor
      editor\paste!

    P: (editor) -> apply editor, (editor) -> editor\paste!

    r: (editor) ->  bindings.capture replace_char

    u: 'editor-undo'
    ctrl_r: 'editor-redo'

    v: (editor) -> state.change_mode editor, 'visual'

    x: (editor) ->
      state.delete = true
      apply editor, (editor, _state) ->
        editor.cursor.pos += (_state.count or 1) - 1
        true

    y: (editor) ->
      if state.yank
        editor\copy_line!
        state.yank = false
      else
        state.yank = true

    Y: (editor) -> editor\copy_line!

    '.': (editor) -> repeat_last editor
  }, __index: base_map.editor

  ':': -> command.run!
}

return setmetatable map, __index: base_map
