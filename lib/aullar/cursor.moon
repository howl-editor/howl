-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Flair = require 'aullar.flair'
callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
C = ffi.C

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'

timer_callback = ffi.cast 'GSourceFunc', callbacks.bool1

is_showing_line = (view, line) ->
  line >= view.first_visible_line and line <= view.last_visible_line

pos_is_in_line = (pos, line) ->
  pos >= line.start_offset and (pos <= line.end_offset or not line.has_eol)

Cursor = {
  new: (@view, @selection) =>
    @_blink_interval = 500
    @width = 1.5

    @_line = 1
    @_column = 1
    @_pos = 1
    @_active = false
    @_showing = true

    @normal_flair = Flair(Flair.RECTANGLE, {
      background: '#c30000'
      background_alpha: 0.9
      width: @width
    })

    -- @normal_flair = Flair(Flair.RECTANGLE, {
    --   foreground: '#c30000'
    --   background: '#c30000'
    --   background_alpha: 0.2
    --   min_width: 3
    -- })

  properties: {
    display_line: => @view.display_lines[@line]
    buffer_line: => @view.buffer\get_line @line

    blink_interval: {
      get: => @_blink_interval
      set: (interval) =>
        @_disable_blink!
        @_enable_blink! if interval > 0
    }

    line: {
      get: => @_line
      set: (line) => @move_to :line
    }

    column: {
      get: => (@pos - @buffer_line.start_offset) + 1
      set: (colum) => @pos = @buffer_line.start_offset + colum - 1
    }

    pos: {
      get: => @_pos
      set: (pos) => @move_to :pos
    }

    active: {
      get: => @_active
      set: (active) =>
        return if active == @_active
        if active
          @_enable_blink!
        else
          @_disable_blink!

        @_active = active
    }
  }

  in_line: (line) =>
    pos_is_in_line @_pos, line

  move_to: (opts) =>
    pos = opts.pos
    if opts.line
      line_nr = max(1, min(opts.line, @view.buffer.nr_lines))
      b_line = @view.buffer\get_line line_nr
      if b_line
        pos = b_line.start_offset

    if pos
      pos = max min(@view.buffer.size + 1, pos), 1
    else
      error("Illegal argument #1 to Cursor.move_to (pos: #{opts.pos}, line: #{opts.line})", 2)

    return if pos == @_pos

    extend_selection = opts.extend or @selection.persistent

    if not extend_selection and not @selection.is_empty
      @selection\clear!

    old_line = @buffer_line
    unless old_line -- old pos/line is gone
      @_pos = @view.buffer.size + 1
      @_line = @view.buffer.nr_lines
      old_line = @view.buffer\get_line(@_line)

    -- are we moving to another line?
    if not pos_is_in_line(pos, old_line) or not is_showing_line @view, old_line.nr
      dest_line = @view.buffer\get_line_at_offset pos
      @_line = dest_line.nr

      if is_showing_line @view, dest_line.nr
        if abs(dest_line.nr - old_line.nr) == 1 -- moving to an adjacent line, do one refresh
          @view\refresh_display min(dest_line.start_offset, old_line.start_offset), max(dest_line.end_offset, old_line.end_offset)
        else -- separated lines, refresh each line separately
          @view\refresh_display old_line.start_offset, old_line.end_offset
          @view\refresh_display dest_line.start_offset, dest_line.end_offset
      else -- scroll
        if dest_line.nr < @view.first_visible_line
          @view.first_visible_line = dest_line.nr
        else
          @view.last_visible_line = dest_line.nr
    else -- staying on same line, refresh it
      @view\refresh_display old_line.start_offset, old_line.end_offset

    if extend_selection
      @selection\extend @_pos, pos

    @_pos = pos
    @_force_show = true
    @_showing = true

    -- finally, do we need to scroll horizontally to show the new position?
    rect = @display_line.layout\index_to_pos @column
    col_pos = rect.x / 1024
    char_width = rect.width / 1024
    x_pos = col_pos - @view.base_x + @view.edit_area_x + @width

    if @view.width and x_pos + char_width > @view.width -- scroll to the right
      @view.base_x = col_pos - @view.edit_area_width + char_width + @width
    elseif x_pos < @view.edit_area_x -- scroll to the left
      @view.base_x = col_pos

  start_of_file: (opts = {}) =>
    @move_to pos: 1, extend: opts.extend

  end_of_file: (opts = {}) =>
    @move_to pos: @view.buffer.size + 1, extend: opts.extend

  forward: (opts = {}) =>
    return if @_pos > @view.buffer.size
    line_start = @buffer_line.start_offset
    z_col = (@_pos - line_start)
    new_index, new_trailing = @display_line.layout\move_cursor_visually true, z_col, 0, 1
    new_index = @buffer_line.size if new_trailing > 0
    if new_index > @buffer_line.size
      @move_to pos: @pos + 1, extend: opts.extend
    else
      @move_to pos: line_start + new_index, extend: opts.extend

  backward: (opts = {}) =>
    return if @_pos == 1
    line_start = @buffer_line.start_offset
    z_col = (@_pos - line_start)
    new_index = @display_line.layout\move_cursor_visually true, z_col, 0, -1
    @move_to pos: line_start + new_index, extend: opts.extend

  up: (opts = {}) =>
    prev = @_get_line @line - 1
    if prev
      @move_to pos: prev.start_offset, extend: opts.extend

  down: (opts = {}) =>
    next = @_get_line @line + 1
    if next
      @move_to pos: next.start_offset, extend: opts.extend

  page_up: (opts = {}) =>
    if @view.first_visible_line == 1
      @start_of_file opts
      return

    first_visible = max(@view.first_visible_line - @view.lines_showing, 1)
    cursor_line_offset = max(@line - @view.first_visible_line, 0)
    @view.first_visible_line = first_visible
    @move_to line: first_visible + cursor_line_offset, extend: opts.extend

  page_down: (opts = {}) =>
    if @view.last_visible_line == @view.buffer.nr_lines
      @end_of_file opts
      return

    cursor_line_offset = max(@line - @view.first_visible_line, 0)
    first_visible = min(@view.last_visible_line, @view.buffer.nr_lines - (@view.lines_showing - 1))

    @view.first_visible_line = first_visible
    @move_to line: first_visible + cursor_line_offset, extend: opts.extend

  start_of_line: (opts = {}) =>
    @move_to pos: @buffer_line.start_offset, extend: opts.extend

  end_of_line: (opts = {}) =>
    @move_to pos: @buffer_line.start_offset + @buffer_line.size, extend: opts.extend

  draw: (x, base_y, cr, display_line) =>
    return unless @_showing
    @normal_flair\draw display_line, @column, @column + 1, x, base_y, cr

  _blink: =>
    return false if not @active
    if @_force_show
      @_force_show = false
      return true

    cur_line = @buffer_line
    @_showing = not @_showing
    @view\refresh_display cur_line.start_offset, cur_line.end_offset
    true

  _get_line: (nr) =>
    @view.buffer\get_line nr

  _enable_blink: =>
    jit.off true, true

    @blink_cb_handle = callbacks.register self._blink, "cursor-blink", @
    @blink_cb_id = C.g_timeout_add_full C.G_PRIORITY_LOW, @blink_interval, timer_callback, cast_arg(@blink_cb_handle.id), nil

  _disable_blink: =>
    if @blink_cb_handle
      callbacks.unregister @blink_cb_handle

    @_showing = true
    -- todo unregister source? will be auto-cancelled by callbacks module though
}

define_class Cursor
