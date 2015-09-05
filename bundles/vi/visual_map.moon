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

  __after_apply: (editor) ->
    -- adjust the selection if needed to cover the selection start pos
    sel = editor.selection
    correct_anchor = sel.cursor < selection_start and selection_start + 1 or selection_start
    sel.anchor = correct_anchor if sel.anchor != correct_anchor
}

setmetatable map, {
  __index: base_map
  __call: (_, editor) ->
    selection_start = editor.cursor.pos
    editor.selection.persistent = true
    with editor.selection
      \set selection_start, selection_start
      .persistent = true
}
return map
