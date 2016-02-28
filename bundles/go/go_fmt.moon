import app, config, mode, signal from howl
import Process from howl.io

append = table.insert

run_command = (contents) ->
  args = {}
  for arg in config.go_fmt_command\gmatch '%S+'
    append args, arg
  args.stdin = contents
  success, out, err, p = pcall Process.execute, args, stdin: contents
  unless success
    log.error out
    return nil
  unless p.successful
    log.error err
    return nil
  out

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
  before = buffer.text
  after = run_command before
  return if not after or after == before

  editor = app\editor_for_buffer buffer
  if editor
    -- reload the contents, adjusting position
    pos = editor.cursor.pos
    top_line = editor.line_at_top
    buffer.text = after
    
    editor.cursor.pos = calculate_new_pos pos, before, after
    editor.line_at_top = top_line
  else
    buffer.text = after

{
  :fmt
}
