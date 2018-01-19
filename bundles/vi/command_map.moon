state = ...
base_map = bundle_load 'base_map'
import apply, record, repeat_last from state
import command, bindings from howl

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

with_lines_selected = (editor, count, f) ->
  current_line = editor.current_line
  lines = editor.buffer.lines
  start_pos = current_line.start_pos
  end_line = lines[current_line.nr + count]
  end_pos = end_line and end_line.start_pos or #editor.buffer + 1

  with editor.selection
    .includes_cursor = false
    \set start_pos, end_pos
    f editor
    .includes_cursor = true

copy_lines = (editor) ->
  state.execute ->
    if not state.count or state.count <= 1
      editor\copy_line!
    else
      editor\with_position_restored ->
        with_lines_selected editor, state.count, (editor) ->
          editor.selection\copy whole_lines: true

  state.reset!

map = {
  __meta: setmetatable {
    name: 'VI'
  }, __index: base_map.__meta

  editor: setmetatable {
    escape: (editor) ->
      state.reset!

    a: (editor) ->
      if editor.cursor.at_end_of_line
        editor\insert ' '
      else
        editor.cursor\right!

      to_insert editor

    A: (editor) ->
      editor.cursor\line_end!
      to_insert editor

    c: (editor) ->
      if not state.change
        state.change = true
        return

      -- cc
      editor.buffer\as_one_undo ->
        for _ = 1, ((state.count or 1) - 1)
          editor\cut!
        editor.cursor\home_indent!
        if not editor.cursor.at_end_of_line
          editor\delete_to_end_of_line!
        to_insert editor

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
        with_lines_selected editor, count, (editor) ->
          editor.selection\cut whole_lines: true

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
      editor\paste where: 'after'

    P: (editor) -> apply editor, (editor) -> editor\paste!

    r: (editor) ->  bindings.capture replace_char

    u: (editor) -> state.execute editor.undo, editor
    ctrl_r: (editor) -> state.execute editor.redo, editor

    v: (editor) -> state.change_mode editor, 'visual'

    x: (editor) ->
      state.delete = true
      apply editor, (editor, _state) ->
        editor.cursor.pos += (_state.count or 1) - 1
        true

    y: (editor) ->
      if state.yank
        copy_lines editor
        state.yank = false
      else
        state.yank = true

    Y: (editor) -> copy_lines editor

    Z: ->
      if state.quitting
        state.reset!
        command.save_and_quit!
      else
        state.quitting = true

    Q: ->
      if state.quitting
        state.reset!
        command.quit_without_save!

    '.': (editor) -> repeat_last editor

    tab: 'navigate-forward'
    ctrl_i: 'navigate-forward'
    ctrl_o: 'navigate-back'
  }, __index: base_map.editor

  ':': -> command.run!
}

return setmetatable map, {
  __index: base_map
  __call: (_, editor) -> state.leave_edit_mode editor
}
