state = ...
base_map = bundle_load 'base_map.moon'

cancel = (editor, mode = 'command') ->
  editor.selection.persistent = false
  editor.selection\remove!
  state.change_mode editor, mode

cut = (editor) ->
  editor.selection\cut!
  cancel editor

copy = (editor) ->
  editor.selection\copy!
  cancel editor

substitute = (editor) ->
  editor.selection\cut!
  cancel editor, 'insert'

map = {
  name: 'VISUAL'
  d: cut
  x: cut
  y: copy
  v: cancel
  s: substitute
  escape: cancel
}

setmetatable map, {
  __index: base_map
  __call: (_, editor) ->
    editor.selection.persistent = true
}
return map
