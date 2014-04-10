-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import Matcher from howl.util
import highlight from howl.ui

class LineInput
  new: (@title, @editor, @lines = editor.buffer.lines) =>
    @completion_options = title: @title, list: column_styles: { 'string' }
    items = [{tostring(l.nr), l.chunk} for l in *@lines]
    @matcher = Matcher items, preserve_order: true
    @editor.buffer\lex @editor.buffer.size

  complete: (text) =>
    return self.matcher(text), @completion_options

  value_for: (value) =>
    nr = tonumber value
    column = nr == @nr and @column or 1
    for line in *@lines
      return line, column if nr == line.nr

    value

  should_complete: => true
  close_on_cancel: => true

  on_selection_changed: (item, readline) =>
    text = readline.text
    highlight.remove_all 'search', @editor.buffer
    @nr = tonumber(item[1])
    @column = 1
    line = @editor.buffer.lines[@nr]
    @editor.line_at_center = @nr

    if text and not text.is_empty
      -- highlight matched text
      start_pos = line.start_pos
      positions = @matcher.explain text, line.text
      if positions
        @column = positions[1]
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
