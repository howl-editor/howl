-- Copyright 2014-2023 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
{string: ffi_string, cast: ffi_cast} = ffi
{:band} = require 'bit'

Gdk = require 'ljglibs.gdk'
Gtk = require 'ljglibs.gtk'
Pango = require 'ljglibs.pango'
cairo = require 'ljglibs.cairo'
signal = require 'ljglibs.gobject.signal'
require 'ljglibs.cairo.context'
DisplayLines = require 'aullar.display_lines'
Cursor = require 'aullar.cursor'
Selection = require 'aullar.selection'
Buffer = require 'aullar.buffer'
Gutter = require 'aullar.gutter'
CurrentLineMarker = require 'aullar.current_line_marker'
config = require 'aullar.config'

{:define_class} = require 'aullar.util'
{:construct_key_event} = require 'ljglibs.util'
{:max, :min, :floor} = math
append = table.insert

jit.off true, true

notify = (view, event, ...) ->
  listener = view.listener
  if listener and listener[event]
    handled = listener[event] view, ...
    return true if handled == true

  false

translate_mouse_event = (g_click, n_press, x, y) ->
  state = g_click\get_current_event_state!
  {
    shift: band(state, Gdk.SHIFT_MASK) != 0
    control: band(state, Gdk.CONTROL_MASK) != 0
    alt: band(state, Gdk.ALT_MASK) != 0
    super: band(state, Gdk.SUPER_MASK) != 0
    hyper: band(state, Gdk.HYPER_MASK) != 0
    meta: band(state, Gdk.META_MASK) != 0
    button: g_click\get_current_button!,
    nr_presses: n_press,
    x: tonumber x,
    y: tonumber y
  }

text_cursor = Gdk.Cursor.new_from_name('text')

View = {
  new: (buffer = Buffer('')) =>
    -- @debug = true
    @_handlers = {}

    @_base_x = 0
    @_first_visible_line = 1
    @_last_visible_line = nil
    @_cur_mouse_cursor = text_cursor
    @_y_scroll_offset = 0
    @width = nil
    @config = config.local_proxy!

    @area = Gtk.DrawingArea {hexpand: true, vexpand: true}
    @area\add_css_class 'htextview'
    @key_controller = Gtk.EventControllerKey!

    @focus_controller = Gtk.EventControllerFocus!
    @gesture_controller = Gtk.GestureClick!
    @gesture_controller.button = 0

    @motion_controller = Gtk.EventControllerMotion!
    with @motion_controller
      append @_handlers, \on_motion self\_on_motion_event

    @scroll_controller = Gtk.EventControllerScroll Gtk.EventControllerScroll.BOTH_AXES
    with @scroll_controller
      append @_handlers, \on_scroll self\_on_scroll

    @area\add_controller @key_controller
    @area\add_controller @focus_controller
    @area\add_controller @gesture_controller
    @area\add_controller @motion_controller
    @area\add_controller @scroll_controller

    @selection = Selection @
    @cursor = Cursor @, @selection
    @cursor.show_when_inactive = @config.view_show_inactive_cursor
    @cursor.blink_interval = @config.cursor_blink_interval

    @gutter = Gutter @, config
    @gutter.visible = config.view_show_line_numbers
    @current_line_marker = CurrentLineMarker @

    @scroll_speed_y = config.scroll_speed_y
    @scroll_speed_x = config.scroll_speed_x

    @im_context = Gtk.ImContextSimple!
    with @im_context
      .client_widget = @area
      append @_handlers, \on_commit (ctx, s) ->
        @insert ffi_string(s), allow_coalescing: true

      append @_handlers, \on_preedit_start ->
        @in_preedit = true
        notify @, 'on_preedit_start'

      append @_handlers, \on_preedit_changed (ctx) ->
        str, attr_list, cursor_pos = ctx\get_preedit_string!
        notify @, 'on_preedit_change', :str, :attr_list, :cursor_pos

      append @_handlers, \on_preedit_end ->
        @in_preedit = false
        notify @, 'on_preedit_end'

    with @area
      .can_focus = true
      .focusable = true

    @_draw_handler = @area\set_draw_func self\_on_draw

    with @key_controller
      append @_handlers, \on_key_pressed self\_on_key_pressed

    with @focus_controller
      append @_handlers, \on_enter self\_on_focus_in
      append @_handlers, \on_leave self\_on_focus_out

    with @gesture_controller
      append @_handlers, \on_pressed self\_on_button_press
      append @_handlers, \on_released self\_on_button_release

    @horizontal_scrollbar = Gtk.Scrollbar Gtk.ORIENTATION_HORIZONTAL
    append @_handlers, @horizontal_scrollbar.adjustment\on_value_changed (adjustment) ->
      return if @_updating_scrolling
      @base_x = floor adjustment.value
      @_draw!
      -- @area\queue_draw!

    -- @horizontal_scrollbar_alignment = Gtk.Alignment {
    --   left_padding: @gutter_width,
    --   @horizontal_scrollbar
    -- }
    -- @horizontal_scrollbar_alignment.no_show_all = not config.view_show_h_scrollbar
    @horizontal_scrollbar.visible = config.view_show_h_scrollbar

    @vertical_scrollbar = Gtk.Scrollbar Gtk.ORIENTATION_VERTICAL
    @vertical_scrollbar.visible = config.view_show_v_scrollbar

    append @_handlers, @vertical_scrollbar.adjustment\on_value_changed (adjustment) ->
      return if @_updating_scrolling
      @_scrolling_vertically = true
      line = floor adjustment.value + 0.5
      @scroll_to line
      @_scrolling_vertically = false

    @bin = Gtk.Box Gtk.ORIENTATION_HORIZONTAL, {
      @gutter\to_gobject!,
      Gtk.Box(Gtk.ORIENTATION_VERTICAL, {
        vexpand: true, hexpand: true
        @area,
        @horizontal_scrollbar
      }),
      @vertical_scrollbar
    }

    append @_handlers, @bin\on_destroy self\_on_destroy
    append @_handlers, @area\on_resize self\_on_resize

    append @_handlers, @bin\on_show =>
      print "view show"

    @_buffer_listener = {
      on_inserted: (_, b, args) -> self\_on_buffer_modified b, args, 'inserted'
      on_deleted: (_, b, args) -> self\_on_buffer_modified b, args, 'deleted'
      on_changed: (_, b, args) -> self\_on_buffer_modified b, args, 'changed'
      on_styled: (_, b, args) -> self\_on_buffer_styled b, args
      on_undo: (_, b, args) -> self\_on_buffer_undo b, args
      on_redo: (_, b, args) -> self\_on_buffer_redo b, args
      on_markers_changed: (_, b, args) -> self\_on_buffer_markers_changed b, args
      last_viewable_line: (_, b) ->
        last = @last_visible_line
        if @height
          last = max last, @height / @default_line_height

        last
    }

    @buffer = buffer
    @config\add_listener self\_on_config_changed

  destroy: =>
    -- @bin\unref!
    @bin\clear_object!
    @bin = nil

  properties: {

    showing: => @height != nil
    has_focus: => @focus_controller.contains_focus
    gutter_width: =>  @config.view_show_line_numbers and @gutter.width or 0

    first_visible_line: {
      get: => @_first_visible_line
      set: (line) => @scroll_to line
    }

    middle_visible_line: {
      get: =>
        return 0 unless @height
        y = 0
        middle = @height / 2

        for line = @_first_visible_line, @_last_visible_line
          d_line = @display_lines[line]
          y += d_line.height
          return line if y >= middle

        @_last_visible_line

      set: (line) =>
        return unless @height
        y = @height / 2
        for nr = line, 1, -1
          d_line = @display_lines[nr]
          y -= d_line.height
          if y <= 0 or nr == 1
            @first_visible_line = nr
            break
    }

    last_visible_line: {
      get: =>
        unless @_last_visible_line
          return 0 unless @height
          @_last_visible_line = 1

          y = 0
          for line in @_buffer\lines @_first_visible_line
            d_line = @display_lines[line.nr]
            break if y + d_line.height > @height
            @_last_visible_line = line.nr
            y += d_line.height

          -- +1 for last visible, since next line might be partially shown
          @display_lines\set_window @_first_visible_line, @_last_visible_line + 1

        @_last_visible_line

      set: (line) =>
        return unless @showing

        last_line_height = @display_lines[line].height
        available = @height - last_line_height
        first_visible = line

        while first_visible > 1
          prev_d_line = @display_lines[first_visible - 1]
          break if (available - prev_d_line.height) < 0
          available -= prev_d_line.height
          first_visible -= 1

        @scroll_to first_visible
        -- we don't actually set @_last_visible_line here as it
        -- will be set by the actuall scrolling
    }

    y_scroll_offset: {
      get: => @_y_scroll_offset
      set: (offset) =>
        @_y_scroll_offset = offset
        if @_y_scroll_offset < -1 or @_y_scroll_offset > 1
          @first_visible_line = max(@first_visible_line + floor(@_y_scroll_offset), 1)
          @_y_scroll_offset = 0
    }

    lines_showing: =>
      @last_visible_line - @first_visible_line + 1

    base_x: {
      get: => @_base_x
      set: (x) =>
        return if @width == 0
        x = floor max(0, x)
        return if x == @_base_x
        @_base_x = x
        @_sync_scrollbars horizontal: true
        @_draw!
    }

    buffer: {
      get: => @_buffer
      set: (buffer) =>
        if @_buffer
          @_buffer\remove_listener(@_buffer_listener)
          @cursor.pos = 1
          @selection\clear!

        @_buffer = buffer
        buffer\add_listener @_buffer_listener

        @last_edit_pos = nil
        @_first_visible_line = 1
        @_base_x = 0
        @_reset_display!
        -- @area\queue_draw!
        buffer\ensure_styled_to line: @last_visible_line + 1
        @_draw!
    }
  }

  grab_focus: =>
    @area\grab_focus!

  scroll_to: (line) =>
    return if line < 1 or not @showing
    line = max(1, line)
    line = min(line, @buffer.nr_lines)
    return if @first_visible_line == line

    @_first_visible_line = line
    @_last_visible_line = nil
    @_sync_scrollbars!
    @buffer\ensure_styled_to line: @last_visible_line + 1

    if line != 1 and @last_visible_line == @buffer.nr_lines
      -- make sure we don't accidentally scroll to much here,
      -- leaving visual area unclaimed
      @last_visible_line = @last_visible_line

    @gutter\sync!
    -- @area\queue_draw!
    @_draw!

  _sync_scrollbars: (opts = { horizontal: true, vertical: true })=>
    @_updating_scrolling = true

    if opts.vertical and @config.view_show_v_scrollbar
      page_size = @lines_showing - 1
      adjustment = @vertical_scrollbar.adjustment
      if adjustment
        adjustment\configure @first_visible_line, 1, @buffer.nr_lines, 1, page_size, page_size

    if opts.horizontal and @config.view_show_h_scrollbar
      max_width = 0
      for i = @first_visible_line, @last_visible_line
        max_width = max max_width, @display_lines[i].width

      max_width += @width_of_space if @config.view_show_cursor

      if max_width <= @width and @base_x == 0
        @horizontal_scrollbar\hide!
      else
        adjustment = @horizontal_scrollbar.adjustment
        if adjustment
          upper = max_width

          if @_scrolling_vertically
            -- we're scrolling vertically so maintain our x,
            -- but ensure we expand the scrollbar if necessary
            adjustment.upper = upper if upper > adjustment.upper
          else
            adjustment\configure @base_x, 1, upper, 10, @width, @width

          @horizontal_scrollbar\show!

    @_updating_scrolling = false
    notify @, 'on_scroll', opts

  insert: (text, opts = {}) =>
    if @selection.is_empty
      @_buffer\insert @cursor.pos, text, #text, opts
    else
      start_pos = @selection\range!
      @_buffer\replace start_pos, @selection.size, text, #text, opts

    notify @, 'on_insert_at_cursor', :text
    nil

  delete_back: (opts = {}) =>
    if @selection.is_empty
      cur_pos = @cursor.pos
      @cursor\backward!
      prev_pos = @cursor.pos
      size = cur_pos - prev_pos
      @cursor.pos = cur_pos

      if size > 0
        text = @_buffer\sub prev_pos, cur_pos
        @_buffer\delete prev_pos, size, opts
        notify @, 'on_delete_back', :text, pos: prev_pos
    else
      start_pos = @selection\range!
      @_buffer\delete start_pos, @selection.size, opts

  to_gobject: => @bin

  refresh_display: (opts = { from_line: 1 }) =>
    return unless @width
    d_lines = @display_lines
    min_y, max_y = nil, nil
    y = 0
    last_valid = 0
    from_line = opts.from_line
    to_line = opts.to_line
    to_offset = opts.to_offset

    unless from_line
      from_offset = min @buffer.size + 1, opts.from_offset
      from_line = @buffer\get_line_at_offset(from_offset).nr

    if opts.invalidate -- invalidate any affected lines before first visible
      for line_nr = from_line, @_first_visible_line - 1
        d_lines[line_nr] = nil

    for line_nr = @_first_visible_line, @last_visible_line + 1
      line = @_buffer\get_line line_nr
      break unless line
      break if to_offset and line.start_offset > to_offset -- after
      break if to_line and line.nr > to_line -- after
      before = line.nr < from_line and line.has_eol
      d_line = d_lines[line_nr]

      if not before
        if opts.invalidate
          d_lines[line.nr] = nil
          -- recreate the display line since subsequent modifications has to
          -- know what the display properties was for the modified lines
          d_lines[line.nr]
        elseif opts.update
          d_line\refresh!

        min_y or= y
        max_y = y + d_line.height

      last_valid = max last_valid, line.nr
      y += d_line.height

    if opts.invalidate -- invalidate any lines after visibly affected block
      local invalidate_to_line

      if not to_line and not to_offset
        invalidate_to_line = d_lines.max
        max_y = @height
        @_last_visible_line = nil
        @display_lines.max = last_valid
      else
        invalidate_to_line = to_line
        if to_offset
          to_offset = min to_offset, @buffer.size + 1
          invalidate_to_line = @buffer\get_line_at_offset(to_offset).nr

      for line_nr = last_valid + 1, invalidate_to_line
        d_lines[line_nr] = nil

    if min_y
      @_draw y1: min_y, y2: max_y, x1: 0, x2: @width

  position_from_coordinates: (x, y, opts = {}) =>
    return nil unless @showing
    cur_y = 0
    return nil unless y >= cur_y

    matched_line = nil

    for line_nr = @_first_visible_line, @last_visible_line + 1
      d_line = @display_lines[line_nr]
      break unless d_line
      end_y = cur_y + d_line.height
      if (y >= cur_y and y <= end_y)
        matched_line = d_line
        break
      elseif opts.fuzzy
        matched_line = d_line

      cur_y = end_y

    if matched_line
      line = @_buffer\get_line(matched_line.nr)
      pango_x = (x - @base_x) * Pango.SCALE
      line_y = max(0, min(y - cur_y, matched_line.text_height - 1)) * Pango.SCALE
      inside, index = matched_line.layout\xy_to_index pango_x, line_y
      if not inside
        -- left of the area, point it to first char in line
        return line.start_offset if x <= 0

        -- right of the area, point to end
        if matched_line.is_wrapped
          v_line = matched_line.lines\at_pixel_y(y - cur_y)
          return line.start_offset + v_line.line_end - 1
        else
          return line.start_offset + line.size
      else
        -- are we aiming for the next grapheme?
        rect = matched_line.layout\index_to_pos index
        if pango_x - rect.x > rect.width * 0.7
          index = matched_line.layout\move_cursor_visually true, index, 0, 1

        return line.start_offset + index

    nil

  coordinates_from_position: (pos) =>
    return nil unless @showing
    line = @buffer\get_line_at_offset pos
    return nil unless line
    return nil if line.nr < @_first_visible_line
    y = 0

    for line_nr = @_first_visible_line, @buffer.nr_lines
      d_line = @display_lines[line_nr]

      if d_line.nr == line.nr or (d_line.nr > line.nr and not line.has_eol)
        -- it's somewhere within this line..
        layout = d_line.layout
        index = pos - line.start_offset -- <-- at this byte index
        rect =  layout\index_to_pos index
        bottom = y + floor((rect.y + rect.height) / Pango.SCALE) + @config.view_line_padding
        return {
          x: floor(rect.x / Pango.SCALE) - @base_x
          x2: floor((rect.x + rect.width) / Pango.SCALE) - @base_x
          y: y + floor(rect.y / Pango.SCALE)
          y2: max(bottom, y + d_line.height)
        }

      y += d_line.height

    nil

  text_dimensions: (text) =>
    p_ctx = @area.pango_context
    layout = Pango.Layout p_ctx
    layout.text = text
    width, height = layout\get_pixel_size!
    :width, height: height + (@config.view_line_padding * 2)

  block_dimensions: (start_line, end_line) =>
    height, width = 0, 0

    for nr = start_line, end_line
      d_line = @display_lines[nr]
      break unless d_line
      width = max width, d_line.width
      height += d_line.height

    width, height

  _invalidate_display: (from_offset, to_offset) =>
    return unless @width

    to_offset = min to_offset, @buffer.size + 1
    from_line = @buffer\get_line_at_offset(from_offset).nr
    to_line = max @display_lines.max, @buffer\get_line_at_offset(to_offset).nr - 1

    for line_nr = from_line, to_line
      @display_lines[line_nr] = nil

  _on_draw: (cr, width, height) =>
    if not @_cairo_ctx
      @_surface = cairo.Surface.create_similar(
        cr.target,
        cairo.CONTENT_COLOR_ALPHA,
        width,
        height
      )
      @_cairo_ctx = cairo.Context @_surface
      @_do_draw cr.clip_extents
      @_redraw_rect = nil
    elseif @_redraw_rect
      @_do_draw @_redraw_rect

    with cr
      .operator = cairo.OPERATOR_SOURCE
      \set_source_surface @_surface, 0, 0
      \rectangle 0, 0, width, height
      \fill!

    @_redraw_rect = nil

  _draw: (clip) =>
    return unless @_cairo_ctx

    if @_redraw_rect
      if clip
        @_redraw_rect.y1 = min(@_redraw_rect.y1, clip.y1)
        @_redraw_rect.y2 = max(@_redraw_rect.y2, clip.y2)
      else
        @_redraw_rect = {y1: 0, y2: @height, x1: 0, x2: @width}
    else
      @_redraw_rect = clip or {y1: 0, y2: @height, x1: 0, x2: @width}

    @area\queue_draw!

  _do_draw: (clip) =>
    return unless @_cairo_ctx
    cr = @_cairo_ctx
    clip or= {y1: 0, y2: @height, x1: 0, x2: @width}
    draw_height = clip.y2 - clip.y1

    -- clear damaged region
    cr.operator = cairo.OPERATOR_CLEAR
    cr\rectangle 0, clip.y1, @width, draw_height
    cr\fill!

    cr.operator = cairo.OPERATOR_OVER

    conf = @config
    line_draw_opts = config: conf, buffer: @_buffer

    y = 0
    cr\move_to 0, y
    cr\set_source_rgb 0, 0, 0

    lines = {}
    start_y = nil

    for line in @_buffer\lines(@_first_visible_line)
      d_line = @display_lines[line.nr]

      if y + d_line.height > clip.y1
        d_line.block -- force evaluation of any block
        lines[#lines + 1] = :line, display_line: d_line
        start_y or= y

      y += d_line.height
      break if y + 1 >= clip.y2

    current_line = @cursor.line
    y = start_y
    cursor_col = @cursor.column

    for line_info in *lines
      {:display_line, :line} = line_info
      line_draw_opts.line = line

      if line.nr == current_line and conf.view_highlight_current_line
        @current_line_marker\draw_before 0, y, display_line, cr, cursor_col

      if @selection\affects_line line
        @selection\draw 0, y, cr, display_line, line

      display_line\draw 0, y, cr, clip, line_draw_opts

      if @selection\affects_line line
        @selection\draw_overlay 0, y, cr, display_line, line

      if line.nr == current_line
        if conf.view_highlight_current_line
          @current_line_marker\draw_after 0, y, display_line, cr, cursor_col

        if conf.view_show_cursor
          @cursor\draw 0, y, cr, display_line

      y += display_line.height
      cr\move_to 0, y

  _reset_display: =>
    @_last_visible_line = nil
    p_ctx = @area.pango_context
    tm = @text_dimensions(' ')
    @width_of_space = tm.width
    @default_line_height = tm.height + floor @config.view_line_padding
    tab_size = @config.view_tab_size
    @_tab_array = Pango.TabArray(1, true, @width_of_space * tab_size)
    @display_lines = DisplayLines @, @_tab_array, @buffer, p_ctx
    @gutter\sync_dimensions @buffer, force: true
    @gutter\sync @
    @refresh_display from_line: 1, invalidate: true

  _on_destroy: =>
    print "view on_destroy"
    @area\unset_draw_func @_draw_handler
    @listener = nil
    @selection = nil
    @cursor\destroy!
    @cursor = nil
    @config\detach!
    @_buffer\remove_listener(@_buffer_listener) if @_buffer

    -- disconnect signal handlers
    for h in *@_handlers
      signal.disconnect h
    print "view on_destroy done"

  _on_buffer_styled: (buffer, args) =>
    return unless @showing
    last_line = buffer\get_line @last_visible_line
    return if args.start_line > @display_lines.max + 1 and last_line.has_eol
    start_line = args.start_line
    start_dline = @display_lines[start_line]
    prev_block = start_dline.block
    prev_block_width = prev_block and prev_block.width

    update_block = (rescan_width) ->
      new_block = @display_lines[start_line].block
      return unless (new_block or prev_block)
      if new_block and prev_block
        if new_block.width == prev_block_width
          return unless rescan_width

          width = 0
          start_scan_line = max(new_block.start_line, @first_visible_line)
          end_scan_line = min(new_block.end_line, @last_visible_line)
          for nr = start_scan_line, end_scan_line
            width = max width, @display_lines[nr].width

          return if width == prev_block_width
          new_block.width = width

      start_refresh = @last_visible_line
      end_refresh = @first_visible_line

      if prev_block
        start_refresh, end_refresh = prev_block.start_line, prev_block.end_line

      if new_block
        start_refresh = min start_refresh, new_block.start_line
        end_refresh = max end_refresh, new_block.end_line

      @refresh_display from_line: start_refresh, to_line: end_refresh

    if not args.invalidated and args.start_line == args.end_line
      -- refresh only the single line, but verify that the modification does not
      -- have other significant percussions
      @refresh_display from_line: start_line, to_line: start_line, invalidate: true

      d_line = @display_lines[start_line]
      if d_line.height == start_dline.height -- height remains the same
        -- but we might still need to adjust for block changes
        update_block(start_dline.width == prev_block_width)
        @_sync_scrollbars horizontal: true
        return

    @refresh_display from_line: start_line, invalidate: true, gutter: true
    -- we might still need to adjust more for block changes
    update_block(start_dline.width == prev_block_width)
    @_sync_scrollbars!

  _on_buffer_modified: (buffer, args, type) =>
    cur_pos = @cursor.pos
    sel_anchor, sel_end = @selection.anchor, @selection.end_pos
    lines_changed = args.lines_changed

    if not @showing
      @_reset_display!
    else
      if lines_changed
        @_last_visible_line = nil

      if args.styled
        @_on_buffer_styled buffer, args.styled
      else
        refresh_all_below = lines_changed

        unless refresh_all_below
          -- refresh only the single line
          buf_line = @buffer\get_line_at_offset args.offset
          start_dline = @display_lines[buf_line.nr]
          @refresh_display from_offset: args.offset, to_offset: args.offset + args.size, invalidate: true
          -- but if the line now has a different height due to line wrapping,
          -- we still want a major refresh
          new_dline = @display_lines[buf_line.nr]
          if new_dline.height != start_dline.height
            refresh_all_below = true
          else
            @_sync_scrollbars horizontal: true

        if refresh_all_below
          @refresh_display from_offset: args.offset, invalidate: true, gutter: true
          @_sync_scrollbars!

      if args.offset > args.invalidate_offset
        -- we have lines before the offset of the modification that are
        -- invalid - they need to be invalidated but not visually refreshed
        @_invalidate_display args.invalidate_offset, args.offset - 1

      @gutter\sync! if lines_changed
      @gutter\sync_dimensions @_buffer
      -- if lines_changed and not @gutter\sync_dimensions buffer
      --   @area\queue_draw!

    -- adjust cursor to correctly reflect the change
    changes = { { :type, offset: args.offset, size: args.size } }
    changes = args.changes if type == 'changed'
    c_pos = cur_pos
    for change in *changes
      if change.type == 'inserted' and change.offset <= c_pos
        c_pos += change.size
      elseif change.type == 'deleted' and change.offset < c_pos
        c_pos -= min(c_pos - change.offset, change.size)

    @cursor\move_to pos: c_pos, force: true

    @selection\clear!

    if @has_focus and args.revision
      with args.revision.meta
        .cursor_before or= cur_pos
        .cursor_after = @cursor.pos
        .selection_anchor = sel_anchor
        .selection_end_pos = sel_end

      @last_edit_pos = @cursor.pos

    -- check whether we should scroll up to fit the contents into the view
    -- we ensure this if the line count was changed, we're showing the last
    -- line, we have non-visible lines above and it was not an insert
    if lines_changed and @_first_visible_line > 1 and type != 'inserted'
      if not @buffer\get_line(@last_visible_line + 1)
        @last_visible_line = @buffer.nr_lines

  _on_buffer_markers_changed: (buffer, args) =>
    @refresh_display {
      from_offset: args.start_offset,
      to_offset: args.end_offset,
      update: true
    }

  _on_buffer_undo: (buffer, revision) =>
    pos = revision.meta.cursor_before or revision.offset
    @cursor.pos = pos
    {:selection_anchor, :selection_end_pos} = revision.meta
    if selection_anchor
      @selection\set selection_anchor, selection_end_pos

  _on_buffer_redo: (buffer, revision) =>
    pos = revision.meta.cursor_after or revision.offset
    @cursor.pos = pos

  _on_focus_in: =>
    @im_context\focus_in!
    @cursor.active = true
    notify @, 'on_focus_in'

  _on_focus_out: =>
    @im_context\focus_out!
    @cursor.active = false
    notify @, 'on_focus_out'

  _on_screen_changed: =>
    @_reset_display!

  _on_key_pressed: (_, keyval, keycode, state) =>
    e = @key_controller\get_current_event!
    if @in_preedit
      @im_context\filter_keypress(e)
      return true

    event = construct_key_event keyval, state
    unless notify @, 'on_key_press', event
      @im_context\filter_keypress(e)

    true

  _on_button_press: (g_click, n_press, x, y) =>
    event = translate_mouse_event g_click, n_press, x, y

    @area\grab_focus! unless @area.has_focus

    return true if notify @, 'on_button_press', event

    return false if event.button != 1

    pos = @position_from_coordinates(event.x, event.y, fuzzy: true)
    if pos
      @selection.persistent = false

      if pos != @cursor.pos
        @cursor\move_to :pos, extend: event.shift
      else
        @selection\clear!

      @_selection_active = true

  _on_button_release: (g_click, n_press, x, y) =>
    event = translate_mouse_event g_click, n_press, x, y
    return true if notify @, 'on_button_release', event
    return if event.button != 1
    @_selection_active = false

  _on_motion_event: (_, x, y) =>
    x, y = tonumber(x), tonumber(y)
    event = :x, :y
    return true if notify @, 'on_motion_event', event
    return unless @_selection_active

    pos = @position_from_coordinates(x, y, fuzzy: true)
    if pos
      @cursor\move_to :pos, extend: true
    elseif y < 0
      if @first_visible_line == 1
        @cursor\move_to pos:1, extend: true
      else
        @cursor\up extend: true
    else
      if @last_visible_line == @buffer.nr_lines
        @cursor\move_to pos:@buffer.size+1, extend: true
      else
        @cursor\down extend: true

  _scroll_x: (value) =>
    value = value * (@scroll_speed_x / 100)

    if value > 0
      -- Scroll right.
      new_base_x = @base_x + 20 * value
      adjustment = @horizontal_scrollbar.adjustment
      if adjustment
        new_base_x = min new_base_x, adjustment.upper - adjustment.page_size
      @base_x = new_base_x
    elseif value < 0
      -- Scroll left.
      @base_x -= 20 * -value

  _scroll_y: (value) =>
    @y_scroll_offset += value * (@scroll_speed_y / 100)

  _on_scroll: (_, delta_x, delta_y) =>
    delta_x, delta_y = tonumber(delta_x), tonumber(delta_y)

    @_scroll_x delta_x if delta_x != 0
    @_scroll_y delta_y if delta_y != 0

  _on_resize: (_, width, height) =>
    width, height = tonumber(width), tonumber(height)
    resized = (not @height or @height != height) or
      (not @width or @width != width)
    return unless resized

    -- For resizes we always recreate our cached surface.
    -- Attempts at keeping cached surfaces with larger sizes only caused
    -- massive performance issues, presumably due to inadvertent scaling
    -- or something
    @_cairo_ctx = nil
    @_surface = nil

    @area.cursor = @_cur_mouse_cursor

    getting_taller = @height and height > @height
    @width = width
    @height = height
    @_reset_display!

    if getting_taller and @last_visible_line == @buffer.nr_lines
      -- since we're growing this could be wrong, and we might need
      -- to re-calculate what the last visible line actually is
      @last_visible_line = @last_visible_line

    @buffer\ensure_styled_to line: @last_visible_line + 1
    @_sync_scrollbars!
    notify @, 'on_resized'

  _on_config_changed: (option, val, old_val) =>
    if option == 'view_show_inactive_cursor'
      @cursor.show_when_inactive = val

    elseif option == 'cursor_blink_interval'
      @cursor.blink_interval = val

    elseif option == 'scroll_speed_y' or option == 'scroll_speed_x'
      @[option] = val

    elseif option == 'gutter_color'
      @gutter\reconfigure @config
      -- @_reset_display!

    elseif option == 'view_show_v_scrollbar'
      @vertical_scrollbar.visible = val

    elseif option == 'view_show_h_scrollbar'
      @horizontal_scrollbar.visible = val
      @horizontal_scrollbar\hide!
      print "set horizontal_scrollbar.visible to #{val}"
      -- @horizontal_scrollbar_alignment.left_padding = @gutter_width

    elseif option == 'view_show_line_numbers'
      @gutter.visible = val

    elseif option\match('^view_')
      @_reset_display!
}

define_class View
