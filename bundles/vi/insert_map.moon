import keyhandler from howl
state = ...

local insert_pos

get_edit = (editor) ->
  return nil unless insert_pos
  cur_line = editor.current_line
  if insert_pos >= cur_line.start_pos and insert_pos <= cur_line.end_pos
    start_pos = (insert_pos - cur_line.start_pos) + 1
    end_pos = (editor.cursor.pos - cur_line.start_pos) + 1
    start_pos, end_pos = end_pos, start_pos if end_pos < start_pos
    text = cur_line\sub start_pos, end_pos - 1
    if text and #text > 0
      (editor) -> editor\insert text


insert_map = {
  name: 'INSERT'
  cursor_properties:
    style: 'line'

  escape: (editor) ->
    state.insert_edit = get_edit editor
    insert_pos = nil
    state.change_mode editor, 'command'
    editor.cursor.column = math.max 1, editor.cursor.column - 1
  }

setmetatable insert_map, {
  __call: (_, editor) -> insert_pos = editor.cursor.pos
  __index: keyhandler.keymap
}

return insert_map
