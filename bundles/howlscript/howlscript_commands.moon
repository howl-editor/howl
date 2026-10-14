-- Copyright 2026 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

-- The howlscript-eval and howlscript-print commands, the counterparts of
-- howl-moon-eval and howl-moon-print (lib/howl/commands/app_commands.moon).

{:app, :breadcrumbs, :log, :mode, :Buffer} = howl
{:ActionBuffer, :BufferPopup} = howl.ui
serpent = require 'serpent'
howlscript = require 'howlscript'

-- Takes the indentation of the first line off all lines, so an indented selection
-- compiles.
dedent = (text) ->
  indent = text\match '^([ \t]*)%S'
  return text unless indent and #indent > 0
  lines = [l\gsub("^#{indent}", '') for l in (text .. '\n')\gmatch '([^\n]*)\n']
  table.concat lines, '\n'

pack = (...) -> { n: select('#', ...), ... }

-- Runs a piece of Howlscript. Returns true and the values it returns, as a table
-- with `n`, or false and an error message.
eval = (text) ->
  f, err = howlscript.loadstring dedent(text), '=howlscript-eval'
  return false, err unless f
  ret = pack pcall f
  return false, ret[2] unless ret[1]
  true, { n: ret.n - 1, unpack(ret, 2, ret.n) }

-- A buffer showing the Lua that a piece of Howlscript compiles to, or the error
-- keeping it from compiling.
to_lua_buffer = (text, title) ->
  lua, err = howlscript.to_lua dedent(text), chunkname: "=#{title}"
  local buf
  if lua
    buf = Buffer mode.by_name 'lua'
    buf.text = lua
  else
    buf = ActionBuffer!
    buf\append err, 'error'

  buf.title = title
  buf.modified = false
  buf

eval_handler = ->
  editor = app.editor
  text = editor.selection.empty and editor.current_line.text or editor.selection.text
  ok, result = eval text
  unless ok
    log.error "(ERROR) => #{result\match '^[^\n]*'}"
    return

  out = ''
  for i = 1, result.n
    out ..= "\n#{serpent.block result[i], comment: false}"

  if editor.popup
    log.info "(Eval) => #{result[1]}"
  else
    buf = Buffer mode.by_name 'lua'
    buf.text = "-- Howl eval (howlscript) =>#{out}"
    editor\show_popup BufferPopup buf, scrollable: true
  howl.clipboard.push out

print_handler = ->
  editor = app.editor
  buffer = editor.buffer
  title = "#{buffer.title} (compiled to Lua)"
  text = buffer.text

  unless editor.selection.empty
    title = "#{buffer.title} (Lua - from selection)"
    text = editor.selection.text

  buf = to_lua_buffer text, title
  if #buf.lines > 20
    breadcrumbs.drop!
    editor.buffer = buf
  else
    buf\insert "-- #{title}\n", 1
    popup = BufferPopup buf, scrollable: true
    editor\show_popup popup, position: 'center'

{
  :dedent
  :eval
  :to_lua_buffer
  commands: {
    {
      name: 'howlscript-eval'
      description: 'Eval the current line or selection as Howlscript and copy result to clipboard'
      handler: eval_handler
    }
    {
      name: 'howlscript-print'
      description: 'Compile and show the Lua for the current Howlscript buffer or selection'
      handler: print_handler
    }
  }
}
