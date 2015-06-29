-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact from howl
import highlight from howl.ui
import Matcher from howl.util

line_match_highlighter = (editor) ->
  local buffer
  (selection, text, items) ->
    if buffer
      highlight.remove_all 'search', buffer
      highlight.remove_all 'search_secondary', buffer

    return unless selection

    buffer = editor.buffer
    line = buffer.lines[selection.line_nr]
    local positions
    if text and not text.is_empty
      positions = Matcher.explain text, line.text

    if positions
      start_pos = line.start_pos
      column = positions[1]
      for hl_pos in *positions
        highlight.apply 'search', buffer, start_pos + hl_pos - 1, 1
    else
      highlight.apply 'search', buffer, line.start_pos, line.end_pos - line.start_pos

    -- highlight nearby secondary matches
    if #items > 0 and not text.is_empty
      local idx

      for i, item in ipairs items
        continue unless item.buffer == buffer
        if item.line_nr >= editor.line_at_top - 5
          idx = i
          break

      if idx
        for i = idx, #items
          continue unless items[i].buffer == buffer
          nr = items[i].line_nr
          if nr > editor.line_at_bottom + 5
            break
          if nr == selection.line_nr
            continue
          line = buffer.lines[nr]
          start_pos = line.start_pos
          positions = Matcher.explain text, line.text
          if positions
            for hl_pos in *positions
              highlight.apply 'search_secondary', buffer, start_pos + hl_pos - 1, 1

interact.register
  name: 'select_line'
  description: 'Selection for buffer lines'
  handler: (opts) ->
    lines = opts.lines
    opts.lines = nil

    unless lines
      error '"lines" field required', 2

    if opts.matcher or opts.items or opts.on_selection_change
      error '"matcher", "items" or "on_selection_change" not allowed', 2

    editor = opts.editor or howl.app.editor
    opts = moon.copy opts
    line_items = [{tostring(line.nr), line.chunk, buffer: line.buffer, line_nr: line.nr, :line} for line in *lines]

    selected_line = opts.selected_line
    if selected_line
      for item in *line_items
        if item.line_nr == selected_line.nr and item.buffer == selected_line.buffer
          opts.selection = item
          break
      opts.selected_line = nil

    matcher = Matcher line_items, preserve_order: true
    opts.matcher = matcher
    opts.on_selection_change = line_match_highlighter(editor)

    result = interact.select_location opts

    if result
      line = result.selection.line
      column = 1
      if result.text and not result.text.is_empty
        positions = matcher.explain result.text, line.text
        column = positions[1]
      return {
        :line
        text: result.text
        :column
      }
    else
      highlight.remove_all 'search', editor.buffer
      highlight.remove_all 'search_secondary', editor.buffer
      return
