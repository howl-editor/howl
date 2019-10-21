-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import interact from howl
import highlight from howl.ui
import Matcher from howl.util

append = table.insert

line_match_highlighter = (editor, explain) ->
  local buffer
  (selection, text, items) ->
    if buffer
      highlight.remove_all 'search', buffer
      highlight.remove_all 'search_secondary', buffer

    return unless selection

    buffer = editor.buffer
    line = buffer.lines[selection.line_nr]
    local segments
    if text and not text.is_empty
      segments = explain text, line.text

    if segments
      start_pos = line.start_pos
      ranges = [{start_pos + s[1] - 1, s[2]} for s in *segments]
      highlight.apply 'search', buffer, ranges
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
        ranges = {}

        for i = idx, #items
          continue unless items[i].buffer == buffer
          nr = items[i].line_nr
          if nr > editor.line_at_bottom + 5
            break
          if nr == selection.line_nr
            continue
          line = buffer.lines[nr]
          start_pos = line.start_pos
          segments = explain text, line.text
          if segments
            for segment in *segments
              ranges[#ranges + 1] = { start_pos + segment[1] - 1, segment[2] }

        highlight.apply 'search_secondary', buffer, ranges

create_matcher = (line_items, find) ->
  mt = {
    __call: (query) =>
      return moon.copy(line_items) unless query
      return [item for item in *line_items when find query, item[2].text]
  }
  return setmetatable {explain: (query, text) -> find query, text}, mt

interact.register
  name: 'select_line'
  description: 'Selection for buffer lines'
  handler: (opts) ->
    opts = moon.copy opts
    lines = opts.lines
    opts.lines = nil

    unless lines
      error '"lines" field required', 2

    if opts.matcher or opts.items or opts.on_change
      error '"matcher", "items" or "on_change" not allowed', 2

    editor = opts.editor or howl.app.editor
    line_items = {}
    largest_nr = 0
    for line in *lines
      append line_items, {tostring(line.nr), line.chunk, buffer: line.buffer, line_nr: line.nr, :line}
      largest_nr = math.max(largest_nr, line.nr)

    selected_line = opts.selected_line
    if selected_line
      for item in *line_items
        if item.line_nr == selected_line.nr and item.buffer == selected_line.buffer
          opts.selection = item
          break
      opts.selected_line = nil

    local matcher
    if opts.find
      matcher = create_matcher(line_items, opts.find)
    else
      matcher = Matcher line_items, preserve_order: true

    opts.items = line_items
    opts.on_change = line_match_highlighter(editor, matcher.explain)
    opts.force_preview = true
    opts.columns = {
        {align: 'right', style: 'comment', min_width: tostring(largest_nr).ulen},
        {}
      }

    result = interact.select_location opts

    if result
      line = result.selection.line
      column = 1
      if result.text and not result.text.is_empty
        segments = matcher.explain result.text, line.text
        column = segments and segments[1][1] or 1
      return {
        :line
        text: result.text
        :column
      }
    else
      highlight.remove_all 'search', editor.buffer
      highlight.remove_all 'search_secondary', editor.buffer
      return

-- howl.interact.select_line lines: howl.app.editor.buffer.lines
