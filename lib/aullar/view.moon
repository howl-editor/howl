-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
bit = require 'bit'
ffi_cast = ffi.cast

Gdk = require 'ljglibs.gdk'
Gtk = require 'ljglibs.gtk'
Pango = require 'ljglibs.pango'
require 'ljglibs.cairo.cairo'
DisplayLines = require 'aullar.display_lines'
Cursor = require 'aullar.cursor'
Selection = require 'aullar.selection'
Buffer = require 'aullar.buffer'
Gutter = require 'aullar.gutter'
CurrentLineMarker = require 'aullar.current_line_marker'
config = require 'aullar.config'

{:define_class} = require 'aullar.util'
{:parse_key_event} = require 'ljglibs.util'
{:max, :min, :abs, :floor} = math

notify = (view, event, ...) ->
  listener = view.listener
  if listener and listener[event]
    handled = listener[event] view, ...
    return true if handled == true

  false

signals = {
  on_draw: (_, cr, view) -> view._draw view, cr

  on_focus_in: (_, _, view) ->
    view._on_focus_in view
    notify view, 'on_focus_in'

  on_focus_out: (_, _, view) ->
    view._on_focus_out view
    notify view, 'on_focus_out'

  on_screen_changed: (_, _, view) -> view._on_screen_changed view
  on_size_allocate: (_, allocation, view) ->
    view._on_size_allocate view, ffi_cast('GdkRectangle *', allocation)
  on_button_press: (_, event, view) ->
    view._on_button_press view, ffi_cast('GdkEventButton *', event)
  on_button_release: (_, event, view) ->
    view._on_button_release view, ffi_cast('GdkEventButton *', event)
  on_motion_event: (_, event, view) ->
    view._on_motion_event view, ffi_cast('GdkEventMotion *', event)
  on_scroll_event: (_, event, view) ->
    view._on_scroll view, ffi_cast('GdkEventScroll *', event)

  on_key_press: (_, e, view) ->
    if view.in_preedit
      ret = view.im_context\filter_keypress(e)
      return true

    event = parse_key_event e
    unless notify view, 'on_key_press', event
      view.im_context\filter_keypress e

    true
}

text_cursor = Gdk.Cursor.new(Gdk.XTERM)

View = {
  new: (buffer = Buffer('')) =>
    @margin = 3
    @_base_x = 0
    @_first_visible_line = 1
    @_last_visible_line = nil
    @_cur_mouse_cursor = text_cursor
    @config = config.local_proxy!

    @area = Gtk.DrawingArea!
    @selection = Selection @
    @cursor = Cursor @, @selection
    @cursor.show_when_inactive = @config.view_show_inactive_cursor
    @cursor.blink_interval = @config.cursor_blink_interval

    @gutter = Gutter @
    @current_line_marker = CurrentLineMarker @

    @im_context = Gtk.ImContextSimple!
    with @im_context
      \on_commit (ctx, s)-> @insert s

      \on_preedit_start ->
        @in_preedit = true
        notify @, 'on_preedit_start'

      \on_preedit_changed (ctx) ->
        str, attr_list, cursor_pos = ctx\get_preedit_string!
        notify @, 'on_preedit_change', :str, :attr_list, :cursor_pos

      \on_preedit_end ->
        @in_preedit = false
        notify @, 'on_preedit_end'

    with @area
      .can_focus = true
      \add_events bit.bor(Gdk.KEY_PRESS_MASK, Gdk.BUTTON_PRESS_MASK, Gdk.BUTTON_RELEASE_MASK, Gdk.POINTER_MOTION_MASK, Gdk.SCROLL_MASK)
      \on_key_press_event signals.on_key_press, @
      \on_button_press_event signals.on_button_press, @
      \on_button_release_event signals.on_button_release, @
      \on_motion_notify_event signals.on_motion_event, @
      \on_scroll_event signals.on_scroll_event, @
      \on_draw signals.on_draw, @
      \on_screen_changed signals.on_screen_changed, @
      \on_size_allocate signals.on_size_allocate, @
      \on_focus_in_event signals.on_focus_in, @
      \on_focus_out_event signals.on_focus_out, @

      font_desc = Pango.FontDescription {
        family: @config.view_font_name,
        size: @config.view_font_size * Pango.SCALE
      }
      \override_font font_desc

    @horizontal_scrollbar = Gtk.Scrollbar Gtk.ORIENTATION_HORIZONTAL
    @horizontal_scrollbar.adjustment\on_value_changed (adjustment) ->
      return if @_updating_scrolling
      @base_x = floor adjustment.value
      @area\queue_draw!

    @horizontal_scrollbar_alignment = Gtk.Alignment {
      left_padding: @gutter_width,
      @horizontal_scrollbar
    }
    @horizontal_scrollbar_alignment.no_show_all = not config.view_show_h_scrollbar

    @vertical_scrollbar = Gtk.Scrollbar Gtk.ORIENTATION_VERTICAL
    @vertical_scrollbar.no_show_all = not config.view_show_v_scrollbar

    @vertical_scrollbar.adjustment\on_value_changed (adjustment) ->
      return if @_updating_scrolling
      @_scrolling_vertically = true
      line = math.floor adjustment.value + 0.5
      @scroll_to line
      @_scrolling_vertically = false

    @bin = Gtk.Box Gtk.ORIENTATION_HORIZONTAL, {
      {
        expand: true,
        Gtk.Box(Gtk.ORIENTATION_VERTICAL, {
          { expand: true, @area },
          @horizontal_scrollbar_alignment
        })
      },
      @vertical_scrollbar
    }

    @_buffer_listener = {
      on_inserted: (_, b, args) -> @\_on_buffer_modified b, args, 'insert'
      on_deleted: (_, b, args) -> @\_on_buffer_modified b, args, 'delete'
      on_styled: (_, b, args) -> @\_on_buffer_styled b, args
      on_undo: (_, b, args) -> @\_on_buffer_undo b, args
      on_redo: (_, b, args) -> @\_on_buffer_redo b, args
      on_marker_changed: (_, b, args) -> @\_on_buffer_marker_changed b, args
      last_line_shown: (_, b) -> @last_visible_line
    }

    @buffer = buffer
    @config\add_listener self\_on_config_changed

  properties: {

    showing: => @height != nil
    has_focus: => @area.is_focus
    gutter_width: =>  @config.view_show_line_numbers and @gutter.width or 0

    first_visible_line: {
      get: => @_first_visible_line
      set: (line) => @scroll_to line
    }

    middle_visible_line: {
      get: =>
        return 0 unless @height
        y = @margin
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
          if y <= @margin or nr == 1
            @first_visible_line = nr
            break
    }

    last_visible_line: {
      get: =>
        unless @_last_visible_line
          return 0 unless @height
          @_last_visible_line = 1

          y = @margin
          for line in @_buffer\lines @_first_visible_line
            d_line = @display_lines[line.nr]
            break if y + d_line.height > @height
            @_last_visible_line = line.nr
            y += d_line.height

        @_last_visible_line

      set: (line) =>
        return unless @showing

        last_line_height = @display_lines[line].height
        available = @height - @margin - last_line_height
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

    lines_showing: =>
      @last_visible_line - @first_visible_line + 1

    base_x: {
      get: => @_base_x
      set: (x) =>
        x = floor max(0, x)
        return if x == @_base_x
        @_base_x = x
        @area\queue_draw!
        @_sync_scrollbars horizontal: true
    }

    edit_area_x: => @gutter_width + @margin
    edit_area_width: =>
      return 0 unless @width
      @width - @edit_area_x

    buffer: {
      get: => @_buffer
      set: (buffer) =>
        if @_buffer
          @_buffer\remove_listener(@_buffer_listener)
          @cursor.pos = 1
          @selection\clear!

        @_buffer = buffer
        buffer\add_listener @_buffer_listener

        @_first_visible_line = 1
        @_base_x = 0
        @_reset_display!
        @area\queue_draw!
        buffer\ensure_styled_to line: @last_visible_line + 1
    }
  }

  grab_focus: => @area\grab_focus!

  scroll_to: (line) =>
    return if line < 1 or not @showing
    line = max(1, line)
    return if @first_visible_line == line

    @_first_visible_line = line
    @_last_visible_line = nil
    @_sync_scrollbars!
    @buffer\ensure_styled_to line: @last_visible_line + 1
    @area\queue_draw!

    if line != 1 and @last_visible_line == @buffer.nr_lines
      -- make sure we don't accidentally scroll to much here,
      -- leaving visual area unclaimed
      @last_visible_line = @last_visible_line

  _sync_scrollbars: (opts = { horizontal: true, vertical: true })=>
    @_updating_scrolling = true

    if opts.vertical
      page_size = @lines_showing - 1
      adjustment = @vertical_scrollbar.adjustment
      if adjustment
        adjustment\configure @first_visible_line, 1, @buffer.nr_lines, 1, page_size, page_size

    if opts.horizontal
      max_width = 0
      for i = @first_visible_line, @last_visible_line
        max_width = max max_width, @display_lines[i].width

      max_width += @width_of_space

      if max_width <= @edit_area_width and @base_x == 0
        @horizontal_scrollbar\hide!
      else
        adjustment = @horizontal_scrollbar.adjustment
        if adjustment
          width = @edit_area_width
          upper = max_width - (@margin / 2)

          if @_scrolling_vertically
            -- we're scrolling vertically so maintain our x,
            -- but ensure we expand the scrollbar if necessary
            adjustment.upper = upper if upper > adjustment.upper
          else
            adjustment\configure @base_x, 1, upper, 10, width, width

          @horizontal_scrollbar\show!

    @_updating_scrolling = false

  insert: (text) =>
    if @selection.is_empty
      @_buffer\insert @cursor.pos, text
    else
      start_pos = @selection\range!
      @_buffer\replace start_pos, @selection.size, text

    notify @, 'on_insert_at_cursor', :text
    nil

  delete_back: =>
    if @selection.is_empty
      cur_pos = @cursor.pos
      @cursor\backward!
      prev_pos = @cursor.pos
      size = cur_pos - prev_pos
      @cursor.pos = cur_pos

      if size > 0
        text = @_buffer\sub prev_pos, cur_pos
        @_buffer\delete(prev_pos, size)
        notify @, 'on_delete_back', :text, pos: prev_pos
    else
      start_pos = @selection\range!
      @_buffer\delete start_pos, @selection.size

  to_gobject: => @bin

  refresh_display: (opts = { from_line: 1 }) =>
    return unless @width
    d_lines = @display_lines
    min_y, max_y = nil, nil
    y = @margin
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
      start_x = @edit_area_x
      start_x = 0 if opts.gutter or start_x == 1
      width = @width - start_x
      height = (max_y - min_y)
      if width > 0 and height > 0
        @area\queue_draw_area start_x, min_y, width, height

  position_from_coordinates: (x, y) =>
    return nil unless @showing
    cur_y = @margin

    for line_nr = @_first_visible_line, @last_visible_line + 1
      d_line = @display_lines[line_nr]
      return nil unless d_line
      end_y = cur_y + d_line.height
      if (y >= cur_y and y <= end_y)
        line = @_buffer\get_line(line_nr)
        pango_x = (x - @edit_area_x + @base_x) * Pango.SCALE
        inside, index = d_line.layout\xy_to_index pango_x, 1
        if not inside
          return line.start_offset + line.size
        else
          -- are we aiming for the next grapheme?
          rect = d_line.layout\index_to_pos index
          if pango_x - rect.x > rect.width * 0.7
            index = d_line.layout\move_cursor_visually true, index, 0, 1

          return line.start_offset + index

      cur_y = end_y

    nil

  coordinates_from_position: (pos) =>
    return nil unless @showing
    line = @buffer\get_line_at_offset pos
    return nil unless line
    return nil if line.nr < @_first_visible_line
    y = @margin
    x = @edit_area_x

    for line_nr = @_first_visible_line, @buffer.nr_lines
      d_line = @display_lines[line_nr]

      if d_line.nr == line.nr or (d_line.nr > line.nr and not line.has_eol)
        -- it's somewhere within this line..
        layout = d_line.layout
        index = pos - line.start_offset -- <-- at this byte index
        rect =  layout\index_to_pos index
        return {
          x: x + (rect.x / Pango.SCALE)
          x2: x + ((rect.x + rect.width) / Pango.SCALE)
          y: y + (rect.y / Pango.SCALE)
          y2: y + (rect.y / Pango.SCALE) + d_line.height
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

  _draw: (cr) =>
    p_ctx = @area.pango_context
    clip = cr.clip_extents
    conf = @config
    line_draw_opts = config: conf, buffer: @_buffer
    draw_gutter = conf.view_show_line_numbers and clip.x1 < @gutter_width

    if draw_gutter
      @gutter\start_draw cr, p_ctx, clip, conf.gutter_styling

    edit_area_x, y = @edit_area_x, @margin
    cr\move_to edit_area_x, y
    cr\set_source_rgb 0, 0, 0

    lines = {}
    start_y = nil

    for line in @_buffer\lines @_first_visible_line
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
        @current_line_marker\draw_before edit_area_x, y, display_line, cr, clip, cursor_col

      if @selection\affects_line line
        @selection\draw edit_area_x, y, cr, display_line, line

      display_line\draw edit_area_x, y, cr, clip, line_draw_opts

      if @selection\affects_line line
        @selection\draw_overlay edit_area_x, y, cr, display_line, line

      if draw_gutter
        @gutter\draw_for_line line.nr, 0, y, display_line

      if line.nr == current_line
        if conf.view_highlight_current_line
          @current_line_marker\draw_after edit_area_x, y, display_line, cr, clip, cursor_col

        if conf.view_show_cursor
          @cursor\draw edit_area_x, y, cr, display_line

      y += display_line.height
      cr\move_to edit_area_x, y

    if draw_gutter
      @gutter\end_draw!

  _reset_display: =>
    @_last_visible_line = nil
    p_ctx = @area.pango_context
    @width_of_space = @text_dimensions(' ').width
    tab_size = @config.view_tab_size
    @_tab_array = Pango.TabArray(1, true, @width_of_space * tab_size)
    @display_lines = DisplayLines @, @_tab_array, @buffer, p_ctx
    @horizontal_scrollbar_alignment.left_padding = @gutter_width
    @gutter\sync_width @buffer, force: true

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
    lines_showing = type == 'delete' and @lines_showing
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

      if lines_changed and not @gutter\sync_width buffer
        @area\queue_draw!

    -- adjust cursor if necessary
    if type == 'insert' and args.offset <= @cursor.pos
      @cursor.pos += #args.text
    elseif type == 'delete' and args.offset < @cursor.pos
      @cursor.pos -= min(@cursor.pos - args.offset, #args.text)

    @selection\clear!

    if @has_focus and args.revision
      with args.revision.meta
        .cursor_before or= cur_pos
        .cursor_after = @cursor.pos
        .selection_anchor = sel_anchor
        .selection_end_pos = sel_end

    -- check whether we should scroll up to fit the contents into the view
    if lines_showing
      if @_first_visible_line > 1 and @lines_showing < lines_showing
        @last_visible_line = @buffer.nr_lines

  _on_buffer_marker_changed: (buffer, marker) =>
    if marker.flair
      @refresh_display from_offset: marker.start_offset, to_offset: marker.end_offset, invalidate: true

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

  _on_focus_out: =>
    @im_context\focus_out!
    @cursor.active = false

  _on_screen_changed: =>
    @_reset_display!

  _on_button_press: (event) =>
    return if event.x <= @gutter_width
    return true if notify @, 'on_button_press', event

    return if event.button != 1 or event.type != Gdk.BUTTON_PRESS

    extend = bit.band(event.state, Gdk.SHIFT_MASK) != 0

    pos = @position_from_coordinates(event.x, event.y)
    if pos
      @area\grab_focus! unless @area.has_focus

      if pos != @cursor.pos
        @cursor\move_to :pos, :extend
      else
        @selection\clear!

      @_selection_active = true

  _on_button_release: (event) =>
    return if event.button != 1
    @_selection_active = false

  _on_motion_event: (event) =>
    unless @_selection_active
      if @_cur_mouse_cursor != text_cursor
        if event.x > @gutter_width
          @area.window.cursor = text_cursor
          @_cur_mouse_cursor = text_cursor
      elseif event.x <= @gutter_width
        @area.window.cursor = nil
        @_cur_mouse_cursor = nil

      return

    pos = @position_from_coordinates(event.x, event.y)
    if pos
      @cursor\move_to :pos, extend: true
    elseif event.y < 0
      @cursor\up extend: true
    else
      @cursor\down extend: true

  _on_scroll: (event) =>
    if event.direction == Gdk.SCROLL_UP
      @scroll_to @first_visible_line - 1
    elseif event.direction == Gdk.SCROLL_DOWN
      @scroll_to @first_visible_line + 1
    elseif event.direction == Gdk.SCROLL_RIGHT
      new_base_x = @base_x + 20
      adjustment = @horizontal_scrollbar.adjustment
      if adjustment
        new_base_x = min new_base_x, adjustment.upper - adjustment.page_size
      @base_x = new_base_x

    elseif event.direction == Gdk.SCROLL_LEFT
      @base_x -= 20

  _on_size_allocate: (allocation) =>
    gdk_window = @area.window
    @im_context.client_window = gdk_window
    if gdk_window != nil
      gdk_window.cursor = @_cur_mouse_cursor

    is_growing = @height and allocation.height > @height
    @width = allocation.width
    @height = allocation.height
    @_reset_display!

    if is_growing and @last_visible_line == @buffer.nr_lines
      -- since we're growing this could be wrong, and we might need
      -- to re-calculate what the last visible line actually is
      @last_visible_line = @last_visible_line

    @_sync_scrollbars!
    @buffer\ensure_styled_to line: @last_visible_line + 1

  _on_config_changed: (option, val, old_val) =>
    if option == 'view_font_name' or option == 'view_font_size'
      @area\override_font Pango.FontDescription {
        family: @config.view_font_name,
        size: @config.view_font_size * Pango.SCALE
      }
      @_reset_display!

    elseif option == 'view_show_inactive_cursor'
      @cursor.show_when_inactive = val

    elseif option == 'cursor_blink_interval'
      @cursor.blink_interval = val

    elseif option == 'view_show_v_scrollbar'
      @vertical_scrollbar.visible = val
      @vertical_scrollbar.no_show_all = true

    elseif option == 'view_show_h_scrollbar'
      @horizontal_scrollbar_alignment.visible = val
      @horizontal_scrollbar_alignment.no_show_all = true
      @horizontal_scrollbar_alignment.left_padding = @gutter_width

    elseif option\match('^view_') or option\match('^gutter')
      @_reset_display!

}

define_class View
