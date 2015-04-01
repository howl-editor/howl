-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact from howl
import highlight from howl.ui
import Matcher from howl.util

selection_change_handler = (editor, buffer, matcher) ->
  (selection, text, items) ->
    highlight.remove_all 'search', buffer
    highlight.remove_all 'search_secondary', buffer

    return if not selection

    editor.line_at_center = selection.lnr
    line = buffer.lines[selection.lnr]

    local positions
    if text and not text.is_empty
      positions = matcher.explain text, line.text

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

      for i, match in ipairs items
        if match.lnr >= editor.line_at_top - 5
          idx = i
          break

      if idx
        for i = idx, #items
          nr = items[i].lnr
          if nr > editor.line_at_bottom + 5
            break
          if nr == selection.lnr
            continue
          line = buffer.lines[nr]
          start_pos = line.start_pos
          positions = matcher.explain text, line.text
          if positions
            for hl_pos in *positions
              highlight.apply 'search_secondary', buffer, start_pos + hl_pos - 1, 1

interact.register
  name: 'select_match'
  description: ''
  handler: (opts) ->
    editor = opts.editor
    buffer = editor.buffer
    lines = opts.lines or buffer.lines
    line_items = [{tostring(l.nr), l.chunk, lnr: l.nr}  for l in *lines]

    selection = nil
    if opts.selected_line
      for item in *line_items
        if item.lnr <= opts.selected_line
          selection = item
        if item.lnr >= opts.selected_line
          break

    matcher = Matcher line_items, preserve_order: true
    column = 1

    final_selection = interact.select
      title:opts.title
      :matcher
      :selection
      on_selection_change: selection_change_handler(editor, buffer, matcher)

    if final_selection
      return {
        row: final_selection.selection.lnr
        col: column
      }
    else
      highlight.remove_all 'search', buffer
      highlight.remove_all 'search_secondary', buffer
      return
