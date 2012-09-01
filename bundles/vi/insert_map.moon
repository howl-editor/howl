import keyhandler from lunar
state = ...

insert_map = {
  name: 'INSERT'
  escape: (editor) -> state.change_mode editor, 'command'
}
moon.extend insert_map, keyhandler.keymap
return insert_map
