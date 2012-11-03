import keyhandler from lunar
state = ...

insert_map = {
  name: 'INSERT'
  cursor_properties:
    style: 'line'

  escape: (editor) -> state.change_mode editor, 'command'
}
moon.extend insert_map, keyhandler.keymap
return insert_map
