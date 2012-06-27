import input from vilu
import getmetatable, setfenv from _G

_G = _G
_ENV = {}
setfenv 1, _ENV

export mode
export delete, change, yank

maps = nil
last_op = nil

export reset = ->
  delete = false
  change = false
  yank = false

export change_mode = (editor, to) ->
  map = maps[to]
  error 'Invalid mode "' .. to .. '"' if not map
  editor.indicator.vi.label = '-- ' .. map.name .. ' --' if editor
  mode = to
  input.keymap = map
  mt = getmetatable map
  map editor if mt.__call

export apply = (editor, f) ->
  editor.buffer\as_one_undo ->
    f editor
    last_op = f

export move = (editor, f) ->
  if delete or change or yank
    _delete, _change, _yank = delete, change, yank
    op = (editor) ->
      start_pos = editor.cursor.pos
      f editor
      with editor.selection
        \set editor.cursor.pos, start_pos
        if _yank then \copy!
        else if _delete then \cut!
        else if _change then
          \cut!
          change_mode editor, 'insert'

    -- yanks are not remembered
    if _delete or _change then apply editor, op
    else op editor

    reset!
  else
    f editor

export repeat_last = (editor) ->
  if last_op then apply editor, last_op

export init = (keymaps, start_mode) ->
  maps = keymaps
  change_mode nil, start_mode

return _ENV
