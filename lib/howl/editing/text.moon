import signal, timer, config, command from howl
tinsert = table.insert

paragraph_at = (line) ->
  lines = {}
  prev = line.previous
  while prev and not prev.blank
    tinsert lines, 1, prev
    prev = prev.previous

  return lines if line.blank and #lines > 0
  tinsert lines, line unless line.blank

  next = line.next
  while next and not next.blank
    tinsert lines, next
    next = next.next

  lines

can_reflow = (line, limit) ->
  len = line.ulen
  first_blank = line\find('%s') or len
  return true if len > limit and first_blank < len

  prev = line.previous
  return true if prev and not prev.blank and prev.ulen + first_blank + 1 <= limit

  next = line.next
  if next and not next.blank
    return true if next.ulen + first_blank + 1 <= limit
    next_first_blank = next\find('%s')
    return true if next_first_blank and len + next_first_blank <= limit

  false

reflow_paragraph_at = (line, limit) ->
  -- find the first line that need to be reflowed
  lines = paragraph_at line
  return unless #lines > 0
  start_line = nil
  for line in *lines
    if can_reflow line, limit
      start_line = line
      break

  return unless start_line -- no, we're good already

  buffer = start_line.buffer
  chunk = buffer\chunk start_line.start_pos, lines[#lines].end_pos
  orig_text = chunk.text
  text = orig_text
  has_eol = orig_text\ends_with buffer.eol
  text = text\sub 1, #text - 1 if has_eol
  text = text\gsub buffer.eol, ' '
  new_lines = {}
  start_pos = 1

  while start_pos and (start_pos + limit <= #text)
    start_search = start_pos + limit
    i = start_search
    while i > start_pos and not text[i].blank
      i -= 1

    if i == start_pos
      i = text\find('[ \t]', start_search) or #text + 1

    if i
      tinsert new_lines, text\sub start_pos, i - 1

    start_pos = i + 1

  tinsert(new_lines, text\sub(start_pos)) if start_pos <= #text
  reflowed = table.concat(new_lines, buffer.eol)
  reflowed ..= buffer.eol if has_eol
  if reflowed != orig_text
    chunk.text = reflowed

-------------------------------------------------------------------------------
-- reflow commands and auto handling
-------------------------------------------------------------------------------

command.register
  name: 'reflow-paragraph',
  description: 'Reflows the current paragraph according to `hard_wrap_column`'
  handler: ->
    cur_line = editor.current_line
    paragraph = paragraph_at cur_line
    if #paragraph > 0
      hard_wrap_column = editor.buffer.config.hard_wrap_column
      reflow_paragraph_at cur_line, hard_wrap_column
      log.info "Reflowed paragraph to max #{hard_wrap_column} columns"
    else
      log.info 'Could not find paragraph to reflow'

command.alias 'reflow-paragraph', 'fill-paragraph'

config.define
  name: 'hard_wrap_column'
  description: 'The column at which to wrap text (hard-wrap)'
  type_of: 'number'
  default: 80

config.define
  name: 'auto_reflow_text'
  description: 'Whether to automatically reflow text according to `hard_wrap_column`'
  type_of: 'boolean'
  default: false

is_reflowing = false

reflow_check = (args) ->
  editor = args.editor
  return if args.as_undo or args.as_redo or not editor

  config = args.buffer.config
  return if is_reflowing or not config.auto_reflow_text

  reflow_at = config.hard_wrap_column
  if not reflow_at
    log.error "`auto_reflow_text` enabled but `hard_wrap_column` is not set"
    return

  -- check whether the modification affects the current line
  cur_line = editor.current_line
  cur_start_pos = cur_line.byte_start_pos
  cur_end_pos = cur_line.byte_end_pos
  start_pos = args.at_pos
  if start_pos >= cur_start_pos and start_pos <= cur_end_pos
    -- it does, but can we reflow?
    if can_reflow cur_line, reflow_at
      timer.asap -> -- can't do modification in callback
        is_reflowing = true
        cur_pos = editor.cursor.pos
        reflow_paragraph_at cur_line, reflow_at
        editor.cursor.pos = cur_pos
        is_reflowing = false
      return true

signal.connect 'text-deleted', reflow_check
signal.connect 'text-inserted', reflow_check

{
  :paragraph_at
  :can_reflow
  :reflow_paragraph_at
}
