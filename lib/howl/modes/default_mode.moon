-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import config, mode from howl
import formatting from howl.editing
import style from howl.ui
append = table.insert

is_comment = (line, comment_prefix) ->
  line\umatch r"^\\s*#{r.escape comment_prefix}"

class DefaultMode
  completers: { 'in_buffer' }

  code_blocks: {}

  indent: (editor, lines=editor.active_lines) =>
    indent_level = editor.buffer.config.indent
    dont_indent_styles = comment: true, string: true
    buffer = editor.buffer
    current_line = editor.current_line

    editor\transform_lines lines, ->
      comment_prefix = @_comment_pair!
      local prev_line

      for line in *lines
        continue if line.is_blank and line.nr != current_line.nr
        local indent

        prev_line or= line.previous_non_blank
        if comment_prefix and prev_line and is_comment(prev_line, comment_prefix)
          indent = prev_line.indentation
        else
          line_start_style = style.at_pos buffer, line.start_pos
          continue if dont_indent_styles[line_start_style]
          indent = @indent_for line, indent_level

        line.indentation = indent if indent != line.indentation
        prev_line = line

    with editor.cursor
      if .line != current_line.nr or .column < current_line.indentation
        \move_to line: current_line.nr, column: current_line.indentation

  comment: (editor, lines=editor.active_lines) =>
    prefix, suffix = @_comment_pair!
    return unless prefix

    prefix ..= ' '
    suffix = ' ' .. suffix unless suffix.is_empty

    buffer, cursor = editor.buffer, editor.cursor
    current_column = cursor.column
    tab_expansion = string.rep ' ', buffer.config.tab_width

    editor\transform_lines lines, ->
      min_indent = math.huge
      min_indent = math.min(min_indent, l.indentation) for l in *lines when not l.is_blank

      for line in *lines
        unless line.is_blank
          text = line\gsub '\t', tab_expansion
          new_text = text\usub(1, min_indent) .. prefix .. text\usub(min_indent + 1) .. suffix
          line.text = new_text

    cursor.column = current_column + #prefix unless current_column == 1

  uncomment: (editor, lines=editor.active_lines) =>
    prefix, suffix = @_comment_pair!
    return unless prefix

    buffer, cursor = editor.buffer, editor.cursor
    pattern = r"()#{r.escape prefix}\\s?().*?()\\s?#{r.escape suffix}()$"
    current_column = cursor.column
    cur_line = editor.current_line
    cur_line_length = #cur_line
    cursor_delta = nil

    editor\transform_lines lines, ->
      for line in *lines
        pfx_start, middle_start, sfx_start, trail_start = line\umatch pattern
        if pfx_start
          head = line\usub 1, pfx_start - 1
          middle = line\usub middle_start, sfx_start - 1
          trail = line\usub trail_start
          line.text = head .. middle .. trail
          cursor_delta = middle_start - pfx_start if line == cur_line

    if cursor_delta
      cursor.column = math.max 1, current_column - cursor_delta

  toggle_comment: (editor, lines=editor.active_lines) =>
    prefix, suffix = @_comment_pair!
    return unless prefix
    pattern = r"^\\s*#{r.escape prefix}.*"

    if lines[1]\umatch pattern
      @uncomment editor, lines
    else
      @comment editor, lines

  structure: (editor) =>
    buffer = editor.buffer
    buf_indent = buffer.config.indent
    threshold = buffer.config.indentation_structure_threshold
    line_levels = {}
    lines = {}

    cur_line = nil
    max_level = 0

    for line in *editor.buffer.lines
      unless line.is_blank
        indentation = line.indentation
        if cur_line and indentation > cur_line.indentation
          unless cur_line\match '%a'
            prev = cur_line.previous
            cur_line = prev if prev and prev.indentation == cur_line.indentation

          if cur_line and cur_line\match '%a'
            level = cur_line.indentation / buf_indent
            max_level = math.max level, max_level
            line_levels[level] = 1 + (line_levels[level] or 0)
            append lines, { line: cur_line, :level }

        cur_line = line

    cut_off = 0
    count = 0

    for i = 0, max_level
      level_count = line_levels[i]
      if level_count
        cut_off = i
        count += level_count
        break if count >= threshold

    [l.line for l in *lines when l.level <= cut_off]

  resolve_type: (context) =>
    pfx = context.prefix
    parts = {}
    leading = pfx\umatch r'((?:\\w+[.:])*\\w+)[.:]\\w*$'
    parts = [p for p in leading\gmatch '%w+'] if leading
    leading, parts

  on_insert_at_cursor: (args, editor) =>
    if args.text == editor.buffer.eol
      buffer = editor.buffer

      if buffer.config.auto_format
        for code_block in * (@code_blocks.multiline or {})
          return true if formatting.ensure_block editor, table.unpack code_block

      cur_line = editor.current_line
      prev_line = cur_line.previous_non_blank
      cur_line.indentation = prev_line.indentation if prev_line
      @indent editor
      true

  indent_for: (line, indent_level) =>
    prev_line = line.previous_non_blank

    if prev_line
      spec = @indentation or {}

      dedent_delta = -indent_level if @patterns_match line.text, spec.less_for
      indent_delta = indent_level if @patterns_match prev_line.text, spec.more_after
      indent_delta = indent_level if not indent_delta and @patterns_match line.text, spec.more_for
      same_delta = 0 if @patterns_match prev_line.text, spec.same_after

      if indent_delta or dedent_delta or same_delta
        delta = (dedent_delta or 0) + (indent_delta or 0) + (same_delta or 0)
        new = prev_line.indentation + delta
        if new < prev_line.indentation and line.indentation <= new
          return line.indentation unless spec.less_for.authoritive

        return new

      -- unwarranted indents
      if spec.more_after and spec.more_after.authoritive != false and line.indentation > prev_line.indentation
        return prev_line.indentation

      if spec.less_for and spec.less_for.authoritive != false and line.indentation < prev_line.indentation
        return prev_line.indentation

      return prev_line.indentation if line.is_blank

    alignment_adjustment = line.indentation % indent_level
    line.indentation + alignment_adjustment

  patterns_match: (text, patterns) =>
    return false unless patterns

    for p in *patterns
      neg_match = nil
      if typeof(p) == 'table'
        p, neg_match = p[1], p[2]

      match = text\umatch p
      if match and (not neg_match or not text\umatch neg_match)
        return true

    false

  _comment_pair: =>
    return unless @comment_syntax
    prefix, suffix = @comment_syntax, ''

    if type(@comment_syntax) == 'table'
      {prefix, suffix} = @comment_syntax

    prefix, suffix

-- Config variables

with config
  .define
    name: 'indentation_structure_threshold'
    description: 'The indentation structure parsing will stop once this number of lines has been collected'
    default: 10
    type_of: 'number'

mode.register name: 'default', create: DefaultMode

DefaultMode
