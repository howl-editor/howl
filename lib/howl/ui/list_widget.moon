-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import PropertyObject from howl.util.moon
import highlight, style, TextWidget, StyledText from howl.ui
import Matcher from howl.util
{:max, :min, :floor} = math

append = table.insert

style.define_default 'list_highlight', color: '#ffffff', underline: true

highlight.define_default 'list_selection', {
  type: highlight.RECTANGLE,
  color: '#888888'
  alpha: 50
  outline_alpha: 100
}

highlight.define_default 'list_selection', {
  type: highlight.UNDERLINE
  text_color: '#000000'
}

reversed = (list) -> [item for item in *list[#list, 1, -1]]

class ListWidget extends PropertyObject
  new: (@matcher, opts={}) =>
    super!
    @opts = moon.copy opts
    @text_widget = TextWidget opts

    with @opts
      .filler_text or= '~'

    @_max_visible_rows = 10
    @_min_visible_rows = 1

    @_columns = { {} }
    @_items = {}
    @page_start_idx = 1
    @page_size = 1
    @selected_idx = nil
    @column_widths = { 1 }
    @highlight_matches_for = nil

  to_gobject: => @text_widget\to_gobject!

  @property showing: get: => @text_widget.showing

  @property columns:
    get: => @_columns
    set: (val) =>
      val = val or { {} }
      @_columns = val
      @_adjust_height!

  @property offset: get: => @page_start_idx

  @property items: get: => @_items

  @property headers:
    get: => [column.header for column in *@_columns]

  @property has_header:
    get: =>
      for header in *@headers
        return true if header
      return false

  @property is_multi_column:
    get: => return #@_columns > 1

  @property has_status:
    get: => #@_items == 0 or #@_items > @text_widget.visible_rows - (@has_header and 1 or 0)

  @property has_items:
    get: => #@_items > 0

  @property nr_columns:
    get: => #@_columns

  _write_page: =>
    @text_widget.buffer\change 1, @text_widget.buffer.size, (buffer) ->
      buffer.text = ''
      @page_size = @text_widget.visible_rows - (@has_status and 1 or 0) - (@has_header and 1 or 0)
      if @has_items and @page_size < 1
        error 'insufficient height - cant display any items'

      items = {}
      last_idx = @page_start_idx + @page_size - 1
      for idx = @page_start_idx, min(last_idx, #@_items)
        append items, @_items[idx]

      buffer\append StyledText.for_table items, @columns

      for _ = 1, last_idx - #@_items
        buffer\append @opts.filler_text..'\n', 'comment'

      header_offset = @has_header and 1 or 0
      for lno = 1, #items
        line = buffer.lines[lno + header_offset]
        @_highlight_matches line.text, line.start_pos

      @_write_status!

    @text_widget.view.first_visible_line = 1
    @text_widget\adjust_height!

  _highlight_matches: (text, start_pos) =>
    if not @highlight_matches_for or @highlight_matches_for.is_empty
      return

    highlighter = self.highlighter or (t) ->
      explain = type(@matcher) == 'table' and @matcher.explain or Matcher.explain
      explain @highlight_matches_for, t

    segments = highlighter text
    if segments
      ranges = {}
      for segment in *segments
        ranges[#ranges + 1] = { start_pos + segment[1] - 1, segment[2] }

      highlight.apply 'list_highlight', @text_widget.buffer, ranges

  _write_status: =>
    return unless @has_status

    last_idx = @page_start_idx + @page_size - 1
    if #@_items < last_idx
      last_idx = #@_items

    status = '(no items)'
    if last_idx > 0
      status = "showing #{@page_start_idx} to #{last_idx} out of #{#@_items}"
      @text_widget.buffer\append '[..] ', 'comment'

    @text_widget.buffer\append status, 'comment'

  _select: (idx) =>
    if not @has_items
      @selected_idx = nil
      @_highlight nil
      return

    if idx < 1
      idx = 1
    elseif idx > #@_items
      idx = #@_items

    @selected_idx = idx

    @_scroll_to idx
    @_highlight idx

    changed = @selection != @previous_selection
    @previous_selection = @selection

    if changed and @opts.on_selection_change
      @opts.on_selection_change @selection

  _scroll_to: (idx) =>
    if @page_start_idx <= idx and @page_start_idx + @page_size > idx
      return

    if idx < @page_start_idx
      @_jump_to_page_at idx
    elseif @page_start_idx + @page_size - 1 < idx
      @_jump_to_page_at idx - @page_size + 1

  _highlight: (idx) =>
    highlight.remove_all 'list_selection', @text_widget.buffer
    return if not idx

    offset = idx - @page_start_idx + 1
    if offset < 1 or offset > @page_size
      error 'selected item is off page'

    offset += 1 if @has_header

    lines = @text_widget.buffer.lines
    pos = lines[offset].start_pos
    length = #lines[offset]
    highlight.apply 'list_selection', @text_widget.buffer, pos, length

  _jump_to_page_at: (idx) =>
    start_of_last_page = #@_items - @page_size + 1
    if idx < 1
      idx = 1
    elseif idx > start_of_last_page
      idx = start_of_last_page

    @page_start_idx = idx
    @_write_page! if @text_widget.showing

  prev_page: =>
    local idx
    if @selected_idx == 1
      idx = #@items
    else
      idx = max 1, @selected_idx - @page_size
    @_jump_to_page_at @page_start_idx + @page_size
    @_select idx

  next_page: =>
    local idx
    if @selected_idx == #@items
      idx = 1
    else
      idx = min #@items, @selected_idx + @page_size
    @_jump_to_page_at @page_start_idx + @page_size
    @_select idx

  select_prev: =>
    return unless @has_items
    @_select @selected_idx > 1 and @selected_idx - 1 or #@items

  select_next: =>
    return unless @has_items
    @_select @selected_idx < #@items and @selected_idx + 1 or 1

  @property selection:
    get: => @selected_idx and @_items and @_items[@selected_idx]
    set: (val) =>
      for idx, item in ipairs @_items
        if item == val
          @_select(idx)
          return
      error "cannot select - #{val} not found"

  @property max_visible_rows:
    get: => @_max_visible_rows
    set: (val) =>
      @_max_visible_rows = val

      if @_min_visible_rows > @_max_visible_rows
        @_min_visible_rows = @_max_visible_rows

      @_adjust_height!

  @property min_visible_rows:
    get: => @_min_visible_rows
    set: (val) =>
      @_min_visible_rows = val
      @_adjust_height!

  @property visible_rows:
    get: => @text_widget.visible_rows

  @property max_height_request:
    set: (height) =>
      default_line_height = @text_widget.view\text_dimensions('M').height
      @max_visible_rows = floor(height / default_line_height)

  @property height: get: => @text_widget.height
  @property width: get: => @text_widget.width

  _adjust_height: =>
    new_visible_rows = #@_items + (@has_header and 1 or 0)
    new_visible_rows = min new_visible_rows, @max_visible_rows
    new_visible_rows = max new_visible_rows, @min_visible_rows

    return if @opts.never_shrink and new_visible_rows < @text_widget.visible_rows

    @text_widget.visible_rows = new_visible_rows

  _adjust_width: =>
    return unless @opts.auto_fit_width
    @text_widget\adjust_width_to_fit!

  show: =>
    return if @showing
    @text_widget\show!
    @_adjust_height!
    @_write_page!
    @_adjust_width!
    if not @selected_idx and @_items
      @_select @opts.reverse and #@_items or 1

  hide: => @text_widget\hide!

  update: (match_text, preserve_position=false) =>
    items = self.matcher match_text
    current_idx = @selected_idx

    if @opts.reverse
      items = reversed items

    @highlight_matches_for= match_text
    @_items = items

    idx = @opts.reverse and #@_items or 1
    if preserve_position and current_idx
      idx = min(current_idx, #@_items)

    @page_start_idx = 1
    if @text_widget.showing
      @_adjust_height!
      @_write_page!
      @_adjust_width!
      @_select idx

  keymap:
    binding_for:
      ['cursor-up']: =>
        @select_prev!

      ['cursor-down']: =>
        @select_next!

      ['cursor-page-up']: =>
        @prev_page!

      ['cursor-page-down']: =>
        @next_page!

return ListWidget
