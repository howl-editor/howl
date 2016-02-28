import app, config, mode, signal from howl
import Process from howl.io

append = table.insert

run_command = (file) ->
  args = {}
  for arg in config.go_fmt_command\gmatch '%S+'
    append args, arg
  append args, file
  success, out, err, p = pcall Process.execute, args
  unless success
    log.error out
    return
  unless p.successful
    log.error err
    return

reload_buffer = (buffer) ->
  buffer.text = buffer.file.contents
  buffer.sync_etag = buffer.file.etag
  buffer.modified = false
  
calculate_new_pos = (pos, before, after) ->
  new_pos = 1
  i = 1
  while i <= pos and new_pos <= #after
    if before[i] == after[new_pos]
      i += 1
      new_pos += 1
    elseif before[i]\match '%s'
      i += 1
    else
      new_pos += 1
  new_pos-1

fmt = (buffer) ->
  return unless buffer.mode.name == 'go'

  file = buffer.file
  before = file.contents
  run_command file

  editor = app\editor_for_buffer buffer
  if editor
    -- reload the contents, adjusting position
    pos = editor.cursor.pos
    top_line = editor.line_at_top
    reload_buffer buffer
    
    editor.cursor.pos = calculate_new_pos pos, before, file.contents
    editor.line_at_top = top_line
  else
    reload_buffer buffer

{
  :fmt
}
