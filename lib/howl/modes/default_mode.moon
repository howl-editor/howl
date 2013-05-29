prev_non_empty_line = (line) ->
  prev_line = line.previous
  while prev_line and prev_line.empty
    prev_line = prev_line.previous
  prev_line

is_match = (text, patterns) ->
  return false unless patterns

  for p in *patterns
    neg_match = nil
    if type(p) == 'table'
      p, neg_match = p[1], p[2]

    match = text\umatch p
    if text\umatch(p) and (not neg_match or not text\umatch neg_match)
      return true

  false

class DefaultMode
  completers: { 'in_buffer' }

  auto_pairs: {
    '(': ')'
    '[': ']'
    '{': '}'
    '"': '"'
    "'": "'"
  }

  indent: (editor) =>
    indent_level = editor.buffer.config.indent

    editor\transform_active_lines (lines) ->
      for line in *lines
        indent = @_indent_for line, indent_level
        line.indentation = indent if indent != line.indentation

      with editor
        .cursor.column = .current_line.indentation + 1 if .cursor.column < .current_line.indentation

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

  on_char_added: (args, editor) =>
    if args.key_name == 'return'
      @indent editor
      true

  _indent_for: (line, indent_level) =>
    prev_line = prev_non_empty_line line

    if prev_line
      return prev_line.indentation + indent_level if is_match prev_line.text, @indent_patterns
      return prev_line.indentation - indent_level if is_match line.text, @dedent_patterns

      -- unwarranted indents
      if @indent_patterns and @indent_patterns.authoritive != false and line.indentation > prev_line.indentation
        return prev_line.indentation

      if @dedent_patterns and @dedent_patterns.authoritive != false and line.indentation < prev_line.indentation
        return prev_line.indentation

      return prev_line.indentation if line.blank

    alignment_adjustment = line.indentation % indent_level
    line.indentation + alignment_adjustment
