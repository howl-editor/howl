import keyhandler from howl
import getmetatable, setfenv, pairs, callable, print, tostring from _G

_G = _G
_ENV = {}
setfenv 1, _ENV

export mode
export delete, change, yank, go
export count, insert_edit

local maps, last_op

export has_modifier = -> delete or change or yank or go

export reset = ->
  delete = false
  change = false
  yank = false
  count = nil
  go = nil
  keyhandler.cancel_capture!

export add_number = (number) ->
  count = count or 0
  count = (count * 10) + number

export change_mode = (editor, to, ...) ->
  map = maps[to]
  error 'Invalid mode "' .. to .. '"' if not map

  if editor
    editor.indicator.vi.label = '-- ' .. map.name .. ' --'
    editor.cursor[k] = v for k,v in pairs map.cursor_properties

  mode = to
  keyhandler.keymap = map
  map(editor, ...) if callable map

export apply = (editor, f) ->
  state = :delete, :change, :yank, :count
  state.has_modifier = delete or change or yank

  op = (editor) -> editor.buffer\as_one_undo ->
    cursor = editor.cursor
    start_pos = cursor.pos
    for i = 1, state.count or 1
      break if true == f editor, state -- count handled by function
    if state.has_modifier
      with editor.selection
        \set start_pos, cursor.pos
        if state.yank
          \copy!
          cursor.pos = start_pos
        else if state.delete
          \cut!
        else if state.change
          \cut!
          change_mode editor, 'insert'

  op editor
  reset!

  if state.delete or state.change
    last_op = op
    insert_edit = nil

export record = (editor, op) ->
  op editor
  reset!
  last_op = op
  insert_edit = nil

export repeat_last = (editor) ->
  if last_op
    for i = 1, count or 1
      last_op editor
      if insert_edit
        insert_edit editor
        change_mode editor, 'command'

  reset!

export init = (keymaps, start_mode) ->
  maps = keymaps
  change_mode nil, start_mode

return _ENV
