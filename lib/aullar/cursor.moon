-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
C = ffi.C

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'

timer_callback = ffi.cast 'GSourceFunc', callbacks.bool1

is_showing_line = (view, line) ->
  line >= view.first_visible_line and line <= view.last_visible_line

Cursor = {
  new: (@view, @selection) =>
    @blink_interval = 500
    @width = 1.5

    @_line = 1
    @_column = 1
    @_pos = 1
    @_active = false
    @_showing = true

  properties: {
    display_line: => @view.display_lines[@line]
    buffer_line: => @view.buffer\get_line @line

    line: {
      get: => @_line
      set: (line) => @move_to :line
    }

    column: {
      get: => @pos - @buffer_line.start_offset - 1
      set: (colum) =>
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
    byte_pos = @_pos - 1
    byte_pos >= line.start_offset and byte_pos <= line.end_offset

  move_to: (opts) =>
    pos = opts.pos
    if opts.line
      b_line = @view.buffer\get_line opts.line
      if b_line
        pos = b_line.start_offset + 1

    if pos
      pos = max min(@view.buffer.size, pos), 0
    else
      error("Illegal argument #1 to Cursor.move_to", 2)

    return if pos == @_pos

    if not @selection.is_empty and not opts.extend
      @selection\clear!

    old_line = @buffer_line

    -- are we moving to another line?
    if pos - 1 < old_line.start_offset or pos - 1 > old_line.end_offset
      dest_line = @view.buffer\get_line_at_offset pos - 1
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

    if opts.extend
      @selection\extend @_pos, pos

    @_pos = pos
    @_force_show = true
    @_showing = true

    -- finally, do we need to scroll horizontally to show the new position?
    rect = @display_line.layout\index_to_pos @column
    col_pos = rect.x / 1024
    char_width = rect.width / 1024
    x_pos = col_pos - @view.base_x + @view.edit_area_x + @width

    if x_pos + char_width > @view.width
      @view.base_x = col_pos - @view.edit_area_width + char_width
      @view\refresh_display!
    elseif x_pos < @view.edit_area_x
      @view.base_x = col_pos
      @view\refresh_display!

  start_of_file: (opts = {}) =>
    @move_to pos: 1, extend: opts.extend

  end_of_file: (opts = {}) =>
    @pos = @view.buffer.size

  forward: (opts = {}) =>
    return if @_pos - 1 == @view.buffer.size
    line_start, line_end = @buffer_line.start_offset, @buffer_line.end_offset
    new_index, new_trailing = @display_line.layout\move_cursor_visually true, @_pos - 1 - line_start, 0, 1
    if new_index > @buffer_line.size
      @move_to pos: @pos + 1, extend: opts.extend
    else
      @move_to pos: line_start + new_index + new_trailing + 1, extend: opts.extend

  backward: (opts = {}) =>
    return if @_pos == 1
    line_start = @buffer_line.start_offset
    new_index = @display_line.layout\move_cursor_visually true, @_pos - 1 - line_start, 0, -1
    @move_to pos: line_start + new_index + 1, extend: opts.extend

  up: (opts = {}) =>
    prev = @_get_line @line - 1
    if prev
      @move_to pos: prev.start_offset + 1, extend: opts.extend

  down: (opts = {}) =>
    next = @_get_line @line + 1
    if next
      @move_to pos: next.start_offset + 1, extend: opts.extend

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
    @move_to pos: @buffer_line.start_offset + 1, extend: opts.extend

  end_of_line: (opts = {}) =>
    @move_to pos: @buffer_line.start_offset + @buffer_line.size + 1, extend: opts.extend

  _blink: =>
    return false if not @active
    if @_force_show
      @_force_show = false
      return true

    cur_line = @buffer_line
    @_showing = not @_showing
    @view\refresh_display cur_line.start_offset, cur_line.end_offset
    true

  draw: (x, base_y, cr, display_line) =>
    return unless @_showing
    cr\save!
    rect = display_line.layout\index_to_pos @column
    cr\set_source_rgb 1, 0, 0
    x = math.max((rect.x / 1024) - 1, 0) + x - @view.base_x
    cr\rectangle x, base_y, @width, display_line.height + 1
    cr\fill!
    cr\restore!

  _get_line: (nr) =>
    @view.buffer\get_line nr

  _enable_blink: =>
    @blink_cb_handle = callbacks.register self._blink, "cursor-blink", @
    @blink_cb_id = C.g_timeout_add_full C.G_PRIORITY_LOW, @blink_interval, timer_callback, cast_arg(@blink_cb_handle.id), nil

  _disable_blink: =>
    callbacks.unregister @blink_cb_handle
    @_showing = true
    -- todo unregister source? will be auto-cancelled by callbacks module though
}

define_class Cursor
