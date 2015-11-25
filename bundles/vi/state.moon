import bindings from howl
import getmetatable, setfenv, pairs, callable, print, tostring, pcall from _G

_G = _G
_ENV = {}
setfenv 1, _ENV

export mode, map
export active, executing = false, false
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
  executing = false
  bindings.cancel_capture!

export execute = (f, ...) ->
  executing = true
  status, ret = pcall f, ...
  reset!
  unless status
    error ret, 2

export add_number = (number) ->
  count = count or 0
  count = (count * 10) + number

export change_mode = (editor, to, ...) ->
  map = maps[to]
  error 'Invalid mode "' .. to .. '"' if not map

  if editor
    meta = map.__meta
    meta.on_enter(editor) if meta.on_enter
    editor.indicator.vi.label = '-- ' .. meta.name .. ' --'
    for k,v in pairs meta.cursor_properties
      v = v! if callable v
      editor.cursor[k] = v

  mode = to
  bindings.pop! if active
  bindings.push map
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

  execute op, editor

  if state.delete or state.change
    last_op = op
    insert_edit = nil

  if map.__after_apply
    map.__after_apply editor

export record = (editor, op) ->
  execute op, editor
  last_op = op
  insert_edit = nil

export repeat_last = (editor) ->
  execute ->
    if last_op
      for i = 1, count or 1
        last_op editor
        if insert_edit
          insert_edit editor
          change_mode editor, 'command'

export init = (keymaps) ->
  maps = keymaps

export activate = (editor) ->
  unless active
    change_mode editor, 'command'
    active = true

export deactivate = ->
  if active
    bindings.pop!
    active = false

return _ENV
