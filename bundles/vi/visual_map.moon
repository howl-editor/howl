state = ...
base_map = bundle_load 'base_map.moon'
import command from lunar

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

  -- hoist on_unhandled up so that we don't have to special case it when delegating
  on_unhandled: base_map.on_unhandled
}

adjust_selection = (editor) ->
  selection = editor.selection
  correct_anchor = selection.cursor < selection_start and selection_start + 1 or selection_start
  selection.anchor = correct_anchor if selection.anchor != correct_anchor

setmetatable map, {
  __index: (key) =>
    target = base_map[key]
    return target if type(target) != 'function'

    (editor, ...) ->
      target editor, ...
      adjust_selection editor

  __call: (_, editor) ->
    editor.selection.persistent = true
    selection_start = editor.cursor.pos
}
return map
