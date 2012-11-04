import keyhandler from lunar
import getmetatable, setfenv, pairs from _G

_G = _G
_ENV = {}
setfenv 1, _ENV

export mode
export delete, change, yank, go
export count

maps = nil
last_op = nil

export reset = ->
  delete = false
  change = false
  yank = false
  count = nil
  go = nil

export add_number = (number) ->
  count = count or 0
  count = (count * 10) + number

export change_mode = (editor, to) ->
  map = maps[to]
  error 'Invalid mode "' .. to .. '"' if not map

  if editor
    editor.indicator.vi.label = '-- ' .. map.name .. ' --'
    editor.cursor[k] = v for k,v in pairs map.cursor_properties

  mode = to
  keyhandler.keymap = map
  mt = getmetatable map
  map editor if mt.__call

export apply = (editor, f) ->
  _delete, _change, _yank, _count = delete, change, yank, count
  op = (editor) -> editor.buffer\as_one_undo ->
    start_pos = editor.cursor.pos
    for i = 1, count or 1 do f editor
    if _delete or _change or _yank
      cur_pos = editor.cursor.pos
      if start_pos != cur_pos
        with editor.selection
          \set cur_pos, start_pos
          if _yank then \copy!
          else if _delete then \cut!
          else if _change then
            \cut!
            change_mode editor, 'insert'
    reset!

  op editor
  last_op = op if _delete or _change

export repeat_last = (editor) ->
  if last_op then last_op editor

export init = (keymaps, start_mode) ->
  maps = keymaps
  change_mode nil, start_mode

return _ENV
