-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import config, formatting, mode from howl
import style from howl.ui

is_comment = (line, comment_prefix) ->
  line\umatch r"^\\s*#{r.escape comment_prefix}"

class DefaultMode
  completers: { 'in_buffer' }

  code_blocks: {}

  indent: (editor) =>
    indent_level = editor.buffer.config.indent
    dont_indent_styles = comment: true, string: true
    buffer = editor.buffer
    current_line = editor.cursor.line

    editor\transform_active_lines (lines) ->
      comment_prefix = @_comment_pair!
      local prev_line

      for line in *lines
        continue if line.blank and line.nr != current_line
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

      with editor
        .cursor.column = .current_line.indentation + 1 if .cursor.column < .current_line.indentation

  comment: (editor) =>
    prefix, suffix = @_comment_pair!
    return unless prefix

    prefix ..= ' '
    suffix = ' ' .. suffix unless suffix.empty

    buffer, cursor = editor.buffer, editor.cursor
    current_column = cursor.column
    tab_expansion = string.rep ' ', buffer.config.tab_width

    editor\transform_active_lines (lines) ->
      min_indent = math.huge
      min_indent = math.min(min_indent, l.indentation) for l in *lines when not l.blank

      for line in *lines
        unless line.blank
          text = line\gsub '\t', tab_expansion
          new_text = text\usub(1, min_indent) .. prefix .. text\usub(min_indent + 1) .. suffix
          line.text = new_text

      cursor.column = current_column + #prefix unless current_column == 1

  uncomment: (editor) =>
    prefix, suffix = @_comment_pair!
    return unless prefix

    buffer, cursor = editor.buffer, editor.cursor
    pattern = r"()#{r.escape prefix}\\s?().*?()\\s?#{r.escape suffix}()$"
    current_column = cursor.column
    cur_line = editor.current_line
    cur_line_length = #cur_line
    cursor_delta = nil

    editor\transform_active_lines (lines) ->
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

  toggle_comment: (editor) =>
    prefix, suffix = @_comment_pair!
    return unless prefix
    pattern = r"^\\s*#{r.escape prefix}.*"

    if editor.active_lines[1]\umatch pattern
      @uncomment editor
    else
      @comment editor

  structure: (editor) =>
    buffer = editor.buffer
    buf_indent = buffer.config.indent
    threshold = buffer.config.indentation_structure_threshold
    line_levels = {}
    lines = {}

    cur_line = nil
    max_level = 0

    for line in *editor.buffer.lines
      unless line.blank
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

  on_char_added: (args, editor) =>
    if args.key_name == 'return'
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
      dedent_delta = -indent_level if @patterns_match line.text, @dedent_patterns
      indent_delta = indent_level if @patterns_match prev_line.text, @indent_after_patterns

      if indent_delta or dedent_delta
        return prev_line.indentation + (dedent_delta or 0) + (indent_delta or 0)

      -- unwarranted indents
      if @indent_after_patterns and @indent_after_patterns.authoritive != false and line.indentation > prev_line.indentation
        return prev_line.indentation

      if @dedent_patterns and @dedent_patterns.authoritive != false and line.indentation < prev_line.indentation
        return prev_line.indentation

      return prev_line.indentation if line.blank

    alignment_adjustment = line.indentation % indent_level
    line.indentation + alignment_adjustment

  patterns_match: (text, patterns) =>
    return false unless patterns

    for p in *patterns
      neg_match = nil
      if type(p) == 'table'
        p, neg_match = p[1], p[2]

      match = text\umatch p
      if text\umatch(p) and (not neg_match or not text\umatch neg_match)
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
