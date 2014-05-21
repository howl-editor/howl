state = ...
base_map = bundle_load 'base_map'

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
  __meta: setmetatable {
    name: 'VISUAL'
  }, __index: base_map.__meta

  editor: setmetatable {
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

    '>': (editor) ->
      editor\shift_right!
      cancel editor

    '<': (editor) ->
      editor\shift_left!
      cancel editor

  }, __index: base_map.editor

  __on_selection_changed: (editor, selection) ->
    if selection.empty and editor.cursor.pos != selection_start
      cancel editor
}

setmetatable map, {
  __index: base_map
  __call: (_, editor) ->
    with editor.selection
      .persistent = true
      selection_start = .anchor
}
return map
