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
        old_line = @view.buffer\get_line @line

        @_pos = pos
        @view\refresh_display old_line.start_offset, old_line.end_offset

        if dest_line.nr != @line
          @view\refresh_display dest_line.start_offset, dest_line.end_offset
          @_line = dest_line.nr
    }
  }

  forward: =>
    @pos += 1 -- xxx

  backward: =>
    return if @_pos == 1
    @pos -= 1 -- xxx

}

(...) -> Object Cursor.new(...), Cursor
