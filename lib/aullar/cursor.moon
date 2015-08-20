-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

flair = require 'aullar.flair'
callbacks = require 'ljglibs.callbacks'
cast_arg = callbacks.cast_arg
ffi = require 'ffi'
C = ffi.C

flair.define_default 'cursor', {
  type: flair.RECTANGLE,
  background: '#000000',
  width: 1.5,
  height: 'text',
}

flair.define_default 'block_cursor', {
  type: flair.RECTANGLE,
  foreground: '#c3c3c3',
  background: '#000000',
  background_alpha: 0.5,
  min_width: 5,
  height: 'text'
  text_color: '#dddddd',
  min_width: 'letter'
}

flair.define_default 'inactive_cursor', {
  type: flair.RECTANGLE,
  foreground: '#cc3333',
  min_width: 5,
  line_width: 1,
  height: 'text',
  min_width: 'letter'
}

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'

timer_callback = ffi.cast 'GSourceFunc', callbacks.bool1

is_showing_line = (view, line) ->
  line >= view.first_visible_line and line <= view.last_visible_line

pos_is_in_line = (pos, line) ->
  pos >= line.start_offset and (pos <= line.end_offset or not line.has_eol)

Cursor = {
  new: (@view, @selection) =>
    @width = 1.5
    @show_when_inactive = true
    @_blink_interval = 500
    @_line = 1
    @_column = 1
    @_pos = 1
    @_active = false
    @_showing = true
    @_sticky_x = nil
    @_style = 'line'
    @_flair = 'cursor'

  properties: {
    display_line: => @view.display_lines[@line]
    buffer_line: => @view.buffer\get_line @line

    style: {
      get: => @_style
      set: (style) =>
        return if style == @_style
        if style == 'block'
          @_flair = 'block_cursor'
        elseif style == 'line'
          @_flair = 'cursor'
        else
          error 'Invalid style ' .. style, 2

        @_style = style
        @_refresh_current_line!
    }

    blink_interval: {
      get: => @_blink_interval
      set: (interval) =>
        @_disable_blink!
        @_blink_interval = interval
        @_showing = true
        @_enable_blink! if interval > 0
    }

    line: {
      get: => @_line
      set: (line) => @move_to :line
    }

    column: {
      get: => (@pos - @buffer_line.start_offset) + 1
      set: (column) => @move_to pos: @buffer_line.start_offset + column - 1
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
          @_flair = @_prev_flair if @_prev_flair
          @_enable_blink!
          @_showing = true
        else
          @_disable_blink!

          if @show_when_inactive
            @_prev_flair = @_flair
            @_flair = 'inactive_cursor'
            @_showing = true
          else
            @_prev_flair = @_flair
            @_showing = false

        @_active = active
        @_refresh_current_line!
    }

    in_view: =>
      @line >= @view.first_visible_line and @line <= @view.last_visible_line
  }

  ensure_in_view: =>
    return if @in_view
    new_line = if @line < @view.first_visible_line
      @view.first_visible_line
    else
      @view.last_visible_line

    @move_to line: new_line

  remember_column: =>
    cur_rect = @display_line.layout\index_to_pos @column - 1
    @_sticky_x = cur_rect.x

  in_line: (line) =>
    pos_is_in_line @_pos, line

  move_to: (opts) =>
    pos = opts.pos
    if opts.line
      line_nr = max(1, min(opts.line, @view.buffer.nr_lines))
      b_line = @view.buffer\get_line line_nr
      if b_line
        pos = b_line.start_offset
        pos += (opts.column - 1) if opts.column

    if pos
      pos = max min(@view.buffer.size + 1, pos), 1
    else
      error("Illegal argument #1 to Cursor.move_to (pos: #{opts.pos}, line: #{opts.line}, column: #{opts.column})", 2)

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
          @view\refresh_display from_line: min(dest_line.nr, old_line.nr), to_line: max(dest_line.nr, old_line.nr)
        else -- separated lines, refresh each line separately
          @view\refresh_display from_line: old_line.nr, to_line: old_line.nr
          @view\refresh_display from_line: dest_line.nr, to_line: dest_line.nr
      else -- scroll
        if dest_line.nr < @view.first_visible_line
          @view.first_visible_line = dest_line.nr
        else
          @view.last_visible_line = dest_line.nr

      -- adjust for the remembered column if appropriate
      if @_sticky_x and (opts.line and not opts.column)
        inside, index = @display_line.layout\xy_to_index @_sticky_x, 1
        index = @display_line.size if not inside and index > 0 -- move to the ending new line
        pos = dest_line.start_offset + index

    else -- staying on same line, refresh it
      @view\refresh_display from_line: old_line.nr, to_line: old_line.nr

    if extend_selection
      @selection\extend @_pos, pos

    @_pos = pos
    @_force_show = true
    @_showing = true

    if not opts.line or not @_sticky_x
      @remember_column!

    -- finally, do we need to scroll horizontally to show the new position?
    rect = @display_line.layout\index_to_pos @column - 1
    col_pos = rect.x / 1024
    char_width = rect.width / 1024
    x_pos = col_pos - @view.base_x + @view.edit_area_x + @width

    if @view.width and x_pos + char_width > @view.width -- scroll to the right
      @view.base_x = col_pos - @view.edit_area_width + char_width + @width
    elseif x_pos < @view.edit_area_x -- scroll to the left
      @view.base_x = col_pos

    -- alert listener if set
    if @listener and @listener.on_pos_changed
      @listener.on_pos_changed @listener, self

  start_of_file: (opts = {}) =>
    @move_to pos: 1, extend: opts.extend

  end_of_file: (opts = {}) =>
    @move_to pos: @view.buffer.size + 1, extend: opts.extend

  forward: (opts = {}) =>
    return if @_pos > @view.buffer.size
    line_start = @buffer_line.start_offset
    z_col = (@_pos - line_start)
    new_index, new_trailing = @display_line.layout\move_cursor_visually true, z_col, 0, 1
    new_index = @display_line.size if new_trailing > 0
    if new_index > @display_line.size
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
    prev = @line - 1
    if prev >= 1
      @move_to line: prev, extend: opts.extend

  down: (opts = {}) =>
    next = @line + 1
    if next <= @view.buffer.nr_lines
      @move_to line: next, extend: opts.extend

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
    return unless @_showing and (@active or @show_when_inactive)
    start_offset = @column
    end_offset, new_trailing = display_line.layout\move_cursor_visually true, start_offset - 1, 0, 1

    if new_trailing > 0 or end_offset > display_line.size + 1
      end_offset = display_line.size + 1
    else
      end_offset += 1

    flair.draw @_flair, display_line, start_offset, end_offset, x, base_y, cr

  _blink: =>
    return false if not @active
    if @_force_show
      @_force_show = false
      return true

    @_showing = not @_showing
    @_refresh_current_line!
    true

  _get_line: (nr) =>
    @view.buffer\get_line nr

  _enable_blink: =>
    return if @_blink_cb_handle
    jit.off true, true

    @_blink_cb_handle = callbacks.register self._blink, "cursor-blink", @
    @blink_cb_id = C.g_timeout_add_full C.G_PRIORITY_LOW, @blink_interval, timer_callback, cast_arg(@_blink_cb_handle.id), nil

  _disable_blink: =>
    if @_blink_cb_handle
      callbacks.unregister @_blink_cb_handle
      @_blink_cb_handle = nil

    -- todo unregister source? will be auto-cancelled by callbacks module though

  _refresh_current_line: =>
    cur_line = @buffer_line
    @view\refresh_display from_line: cur_line.nr, to_line: cur_line.nr
 }

define_class Cursor
