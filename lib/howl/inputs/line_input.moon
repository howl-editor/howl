-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Matcher from howl.util
import highlight from howl.ui

class LineInput
  new: (@title, buffer, @editor, @lines = buffer.lines) =>
    @completion_options = title: @title, list: column_styles: { 'string' }
    items = [{tostring(l.nr), l.chunk} for l in *@lines]
    @matcher = Matcher items, preserve_order: true
    buffer\lex buffer.size

  complete: (text) =>
    return self.matcher(text), @completion_options

  value_for: (value) =>
    nr = tonumber value
    for line in *@lines
      return line if nr == line.nr

    value

  should_complete: => true
  close_on_cancel: => true

  on_selection_changed: (item, readline) =>
    text = readline.text
    highlight.remove_all 'search', @editor.buffer
    nr = tonumber(item[1])
    line = @editor.buffer.lines[nr]
    @editor.sci\scroll_range(line.byte_end_pos, line.byte_start_pos)

    if text and not text.is_empty
      -- highlight matched text
      start_pos = line.start_pos
      positions = @matcher.explain text, line.text
      if positions
        for hl_pos in *positions
          highlight.apply 'search', @editor.buffer, start_pos + hl_pos - 1, 1
    else
      -- highlight entire line
      highlight.apply 'search', @editor.buffer, line.start_pos, line.end_pos - line.start_pos

howl.inputs.register {
  name: 'line',
  description: 'Return a Line object for a line in the current buffer'
  factory: LineInput
}
