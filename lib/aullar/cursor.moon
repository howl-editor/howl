-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

-- {:max, :min, :abs} = math
{:Object} = require 'aullar.util'

Cursor = {
  new: (view) ->
    {
      :view
      _line: 1
      _column: 1
      _pos: 1
    }

  properties: {
    display_line: => @view.display_lines[@line]
    buffer_line: => @view.buffer\get_line @line

    line: {
      get: => @_line
      set: (line) =>
    }

    column: {
      get: => @_colum
      set: (colum) =>
    }

    pos: {
      get: => @_pos
      set: (pos) =>
        dest_line = @view.buffer\get_line_at_offset pos - 1
        return unless dest_line
        old_line = @buffer_line

        @_pos = pos
        @view\refresh_display old_line.start_offset, old_line.end_offset

        if dest_line.nr != @line
          @view\refresh_display dest_line.start_offset, dest_line.end_offset
          @_line = dest_line.nr
    }
  }

  forward: =>
    return if @_pos - 1 == @view.buffer.size
    line_start, line_end = @buffer_line.start_offset, @buffer_line.end_offset
    new_index, new_trailing = @display_line.layout\move_cursor_visually true, @_pos - 1 - line_start, 0, 1
    if new_index > @buffer_line.size
      @pos += 1
    else
      @pos = line_start + new_index + new_trailing + 1

  backward: =>
    return if @_pos == 1
    line_start = @buffer_line.start_offset
    new_index = @display_line.layout\move_cursor_visually true, @_pos - 1 - line_start, 0, -1
    @pos = line_start + new_index + 1

  up: =>
    prev = @_get_line @line - 1
    if prev
      @pos = prev.start_offset + 1

  down: =>
    next = @_get_line @line + 1
    if next
      @pos = next.start_offset + 1

  _get_line: (nr) =>
    @view.buffer\get_line nr

}

(...) -> Object Cursor.new(...), Cursor
