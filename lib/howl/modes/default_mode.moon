class DefaultMode
  completers: { 'in_buffer' }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

  comment: (editor) =>
    buffer, cursor = editor.buffer, editor.cursor
    prefix = @short_comment_prefix
    return unless prefix
    prefix ..= ' '
    current_column = cursor.column
    tab_expansion = string.rep ' ', buffer.config.tab_width

    editor\transform_active_lines (lines) ->
      min_indent = math.huge
      min_indent = math.min(min_indent, l.indentation) for l in *lines when not l.blank

      for line in *lines
        unless line.blank
          text = line\gsub '\t', tab_expansion
          new_text = text\usub(1, min_indent) .. prefix .. text\usub(min_indent + 1)
          line.text = new_text

      cursor.column = current_column + #prefix unless current_column == 1

  uncomment: (editor) =>
    buffer, cursor = editor.buffer, editor.cursor
    prefix = @short_comment_prefix
    return unless prefix
    pattern = r"()#{r.escape prefix}\\s?()"
    current_column = cursor.column
    cur_line_length = #editor.current_line

    editor\transform_active_lines (lines) ->
      for line in *lines
        start_pos, end_pos = line\umatch pattern
        if start_pos
          line.text = line\sub(1, start_pos - 1) .. line\sub(end_pos)

      cursor.column = math.max 1, current_column - (cur_line_length - #editor.current_line)

  toggle_comment: (editor) =>
    prefix = @short_comment_prefix
    return unless prefix
    pattern = r"^\\s*#{r.escape prefix}.*"

    if editor.active_lines[1]\umatch pattern
      @uncomment editor
    else
      @comment editor
