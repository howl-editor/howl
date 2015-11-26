state = ...
base_map = bundle_load 'base_map'

import command from howl

local selection_start

cancel = (editor, mode = 'command') ->
  editor.selection.persistent = false
  editor.selection\remove!
  state.change_mode editor, mode
  true

cut = (editor) ->
  editor.selection\cut!
  cancel editor

copy = (editor) ->
  editor.selection\copy!
  cancel editor

substitute = (editor) ->
  editor.selection\cut!
  cancel editor, 'insert'

ensure_correct_sel_range = (sel) ->
  return if not selection_start or sel.empty
  correct_anchor = sel.cursor < selection_start and selection_start + 1 or selection_start
  if sel.anchor != correct_anchor
    sel.anchor = correct_anchor

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
    if selection.empty
      if editor.cursor.pos != selection_start
        cancel editor
    else
      ensure_correct_sel_range selection

  __after_apply: (editor) ->
    ensure_correct_sel_range editor.selection
}

setmetatable map, {
  __index: base_map
  __call: (_, editor) ->
    selection = editor.selection
    selection.persistent = true

    if selection.anchor
      selection_start = selection.anchor
      ensure_correct_sel_range selection
    else
      selection_start = editor.cursor.pos
      selection\set selection_start, selection_start
}

return map
