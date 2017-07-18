ends_previous_block = (line, block_start_p) ->
  line = line.previous
  while line and not line.is_blank
    return true if line\umatch block_start_p
    line = line.previous

  false

{
  ensure_block: (editor, block_start_p, block_end_p, end_s) ->
    line = editor.current_line
    prev_line = line.previous
    return unless prev_line
    start_line_indent = prev_line.indentation
    modified = false

    opening_pos = prev_line\ufind(block_start_p)
    return false unless opening_pos

    if prev_line\umatch(block_end_p, opening_pos + 1) -- closed on same line
      return false

    -- but for the ugly cases where the start and end are the same
    -- check whether this is likely to be a completed block
    uniform = end_s\umatch block_start_p
    if uniform and ends_previous_block(prev_line, block_start_p)
      return false

    lines = editor.buffer.lines

    -- check whether we need to add the end_s ourselves
    unless line.text\umatch(block_end_p)
      return false unless line.is_blank
      next_line = line.next_non_blank
      while next_line and not next_line.is_blank
        return false if next_line.indentation > start_line_indent
        return false if next_line.indentation == start_line_indent and next_line\umatch(block_end_p)
        break if next_line\umatch block_start_p
        next_line = next_line.next

      lines\insert line.nr + 1, end_s
      modified = true

    -- add a blank line between the start and end line if necessary
    unless line.is_blank
      line = lines\insert line.nr, ''
      modified = true

    if modified -- fix up indentation and cursor position
      new_indent = start_line_indent + editor.config_at_cursor.indent
      line.indentation = new_indent
      line.next.indentation = start_line_indent

      with editor
        .cursor.line = line.nr
        \indent!
        .cursor.column = line.indentation + 1

    modified
}
