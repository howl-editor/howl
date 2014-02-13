{
  ensure_block: (editor, block_start_p, block_end_p, end_s) ->
    line = editor.current_line
    prev_line = line.previous_non_blank
    return unless prev_line
    start_line_indent = prev_line.indentation
    modified = false

    if prev_line\umatch(block_start_p)
      lines = editor.buffer.lines

      -- check whether we need to add the end_s ourselves
      unless line.text\umatch(block_end_p)
        return false unless line.is_blank
        next_line = line.next_non_blank
        if next_line
          return false if next_line.indentation > start_line_indent
          return false if next_line.indentation == start_line_indent and next_line\umatch(block_end_p)

        lines\insert line.nr + 1, end_s
        modified = true

      -- add a blank line between the start and end line if necessary
      unless line.is_blank
        line = lines\insert line.nr, ''
        modified = true

      if modified -- fix up indentation and cursor position
        new_indent = start_line_indent + editor.buffer.config.indent
        line.indentation = new_indent
        line.next.indentation = start_line_indent

        with editor
          .cursor.line = line.nr
          \indent!
          .cursor.column = line.indentation + 1

    modified
}
