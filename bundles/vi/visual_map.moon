state = ...
base_map = bundle_load 'base_map.moon'

import command from howl

local selection_start

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
  i: (editor) ->
    editor.selection.persistent = false
    state.change_mode editor, 'insert'
  ':': -> command.run!
}

setmetatable map, {
  __index: base_map
  __call: (_, editor) ->
    editor.selection.persistent = true
    selection_start = editor.cursor.pos
}
return map
