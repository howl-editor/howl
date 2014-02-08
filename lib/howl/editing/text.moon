import signal, timer, config, command from howl
import style from howl.ui
tinsert = table.insert

paragraph_line = (line) -> line\umatch r'^\\pL'

paragraph_at = (line) ->
  lines = {}
  prev = line.previous
  while prev and paragraph_line prev
    tinsert lines, 1, prev
    prev = prev.previous

  return lines if line.blank and #lines > 0
  tinsert lines, line if paragraph_line line

  next = line.next
  while next and paragraph_line next
    tinsert lines, next
    next = next.next

  lines

can_reflow = (line, limit) ->
  len = line.ulen
  first_blank = line\find('[\t ]')
  if len > limit
    return false if not first_blank
    return true if first_blank <= len

  cut_off = first_blank or len

  prev = line.previous
  return true if prev and not prev.blank and prev.ulen + cut_off + 1 <= limit

  next = line.next
  if next and not next.blank
    return true if next.ulen + cut_off + 1 <= limit
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
  text = text\usub 1, text.ulen - 1 if has_eol
  text = text\gsub buffer.eol, ' '
  new_lines = {}
  start_pos = 1

  while start_pos and (start_pos + limit <= text.ulen)
    start_search = start_pos + limit
    i = start_search
    while i > start_pos and not text[i].blank
      i -= 1

    if i == start_pos
      i = text\ufind('[ \t]', start_search) or text.ulen + 1

    if i
      tinsert new_lines, text\usub start_pos, i - 1

    start_pos = i + 1

  tinsert(new_lines, text\usub(start_pos)) if start_pos <= text.ulen
  reflowed = table.concat(new_lines, buffer.eol)
  reflowed ..= buffer.eol if has_eol
  reflowed ..= buffer.eol if start_pos == text.ulen + 1

  if reflowed != orig_text
    chunk.text = reflowed

-------------------------------------------------------------------------------
-- reflow commands and auto handling
-------------------------------------------------------------------------------

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

do_reflow = (editor, line, reflow_at) ->
  is_reflowing = true
  cur_pos = editor.cursor.pos
  reflow_paragraph_at line, reflow_at
  editor.cursor.pos = cur_pos
  is_reflowing = false

command.register
  name: 'reflow-paragraph',
  description: 'Reflows the current paragraph according to `hard_wrap_column`'
  handler: ->
    cur_line = editor.current_line
    paragraph = paragraph_at cur_line
    if #paragraph > 0
      hard_wrap_column = editor.buffer.config.hard_wrap_column
      do_reflow editor, cur_line, hard_wrap_column
      log.info "Reflowed paragraph to max #{hard_wrap_column} columns"
    else
      log.info 'Could not find paragraph to reflow'

command.alias 'reflow-paragraph', 'fill-paragraph'

reflow_check = (args) ->
  editor = args.editor
  return if args.as_undo or args.as_redo or not editor

  config = args.buffer.config
  return if is_reflowing or not config.auto_reflow_text

  at_pos = args.buffer\char_offset args.at_pos
  cur_style = style.at_pos args.buffer, math.max(at_pos - 1, 1)
  return if cur_style\contains 'embedded'

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
      -- can't do modification in callback so do it asap
      timer.asap do_reflow, editor, cur_line, reflow_at
      return true

signal.connect 'text-deleted', reflow_check
signal.connect 'text-inserted', (args) ->
  reflow_check(args) unless args.text == args.buffer.eol

{
  :paragraph_at
  :can_reflow
  :reflow_paragraph_at
}
