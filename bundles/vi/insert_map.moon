import keyhandler from howl
state = ...

insert_map = {
  name: 'INSERT'
  cursor_properties:
    style: 'line'

  escape: (editor) ->
    state.change_mode editor, 'command'
    editor.cursor.column = math.max 1, editor.cursor.column - 1
}
moon.extend insert_map, keyhandler.keymap
return insert_map
