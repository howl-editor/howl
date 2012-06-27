import input from vilu
state = ...

insert_map = {
  name: 'INSERT'
  escape: (editor) -> state.change_mode editor, 'command'
}
moon.extend insert_map, input.keymap
return insert_map
