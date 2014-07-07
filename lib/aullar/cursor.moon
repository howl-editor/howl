-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'

is_showing_line = (view, line) ->
  line >= view.first_visible_line and line <= view.last_visible_line

Cursor = {
  new: (@view) =>
    @_line = 1
    @_column = 1
    @_pos = 1

  properties: {
    display_line: => @view.display_lines[@line]
    buffer_line: => @view.buffer\get_line @line

    line: {
      get: => @_line
      set: (line) =>
        b_line = @view.buffer\get_line line
        if b_line
          @pos = b_line.start_offset + 1
    }

    column: {
      get: => @_colum
      set: (colum) =>
    }

    pos: {
      get: => @_pos
      set: (pos) =>
        return if pos == @_pos

        pos = min(@view.buffer.size, pos)
        pos = max(pos, 0)
        old_line = @buffer_line
        @_pos = pos

        -- are we moving to another line?
        if pos - 1 < old_line.start_offset or pos - 1 > old_line.end_offset
          dest_line = @view.buffer\get_line_at_offset pos - 1
          @_line = dest_line.nr

          if is_showing_line @view, dest_line.nr
            @view\refresh_display dest_line.start_offset, dest_line.end_offset
          else -- scroll
            if dest_line.nr < @view.first_visible_line
              @view.first_visible_line = dest_line.nr
            else
              @view.last_visible_line = dest_line.nr
            return

        @view\refresh_display old_line.start_offset, old_line.end_offset
    }
  }

  start_of_file: =>
    @pos = 1

  end_of_file: =>
    @pos = @view.buffer.size

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

  page_up: =>
    if @view.first_visible_line == 1
      @start_of_file!
      return

    first_visible = max(@view.first_visible_line - @view.lines_showing, 1)
    cursor_line_offset = max(@line - @view.first_visible_line, 1)
    @view.first_visible_line = first_visible
    @line = first_visible + cursor_line_offset

  page_down: =>
    if @view.last_visible_line == @view.buffer.nr_lines
      @end_of_file!
      return

    cursor_line_offset = max(@line - @view.first_visible_line, 1)
    first_visible = min(@view.last_visible_line, @view.buffer.nr_lines - @view.lines_showing)

    @view.first_visible_line = first_visible
    @line = first_visible + cursor_line_offset

  _get_line: (nr) =>
    @view.buffer\get_line nr

}

define_class Cursor
