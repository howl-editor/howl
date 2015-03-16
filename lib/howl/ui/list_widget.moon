-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import Scintilla from howl
import PropertyObject from howl.aux.moon
import highlight, style, TextWidget, StyledTable from howl.ui
import Matcher from howl.util

append = table.insert

style.define_default 'list_highlight', color: '#ffffff', underline: true

highlight.define_default 'list_selection', {
  style: highlight.ROUNDBOX,
  color: '#888888'
  alpha: 50
  outline_alpha: 100
}

reversed = (list) -> [item for item in *list[#list, 1, -1]]

class ListWidget extends PropertyObject
  new: (@matcher, opts={}) =>
    super!
    @swidget = TextWidget!

    @opts = moon.copy opts
    with @opts
      .filler_text or= '~'

    @_max_height = 10 * @swidget.row_height * 10
    @_min_height = 1 * @swidget.row_height * 1

    @_columns = { { } }
    @_items = {}
    @page_start_idx = 1
    @page_size = 1
    @selected_idx = nil
    @column_widths = { 1 }
    @highlight_matches_for = nil

  to_gobject: => @swidget\to_gobject!

  @property showing: get: => @swidget.showing

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
    get: => #@_items == 0 or #@_items > @swidget.height_rows - (@has_header and 1 or 0)

  @property has_items:
    get: => #@_items > 0

  @property num_columns:
    get: => #@_columns

  _write_page: =>
    @swidget.buffer.text = ''
    @page_size = @swidget.height_rows - (@has_status and 1 or 0) - (@has_header and 1 or 0)
    if @has_items and @page_size < 1
      error 'insufficient height - cant display any items'

    items = {}
    last_idx = @page_start_idx + @page_size - 1
    for idx = @page_start_idx, math.min(last_idx, #@_items)
      append items, @_items[idx]

    @swidget.buffer\append StyledTable items, @columns

    for i = 1, last_idx - #@_items
      @swidget.buffer\append @opts.filler_text..'\n', 'comment'

    header_offset = @has_header and 1 or 0
    for lno = 1, #items
      line = @swidget.buffer.lines[lno + header_offset]
      @_highlight_matches line.text, line.start_pos

    @_write_status!

  _highlight_matches: (text, start_pos) =>
    if not @highlight_matches_for or @highlight_matches_for.is_empty
      return

    highlighter = self.highlighter or (text) ->
      Matcher.explain @highlight_matches_for, text

    positions = highlighter text
    if positions
      for hl_pos in *positions
        p = start_pos + hl_pos - 1
        @swidget.buffer\style p, p, 'list_highlight'

  _write_status: =>
    return unless @has_status

    last_idx = @page_start_idx + @page_size - 1
    if #@_items < last_idx
      last_idx = #@_items

    status = '(no items)'
    if last_idx > 0
      status = "showing #{@page_start_idx} to #{last_idx} out of #{#@_items}"
      @swidget.buffer\append '[..] ', 'comment'

    @swidget.buffer\append status, 'comment'

  _select: (idx) =>
    if not @has_items
      @selected_idx = nil
      @_highlight nil
      return

    if idx < 1
      idx = 1
    if idx > #@_items
      idx = #@_items

    @selected_idx = idx

    @_scroll_to idx
    @_highlight idx

  _scroll_to: (idx) =>
    if @page_start_idx <= idx and @page_start_idx + @page_size > idx
      return

    edge_gap = math.min 1, @page_size - 1
    if idx < @page_start_idx
      @_jump_to_page_at idx - @page_size + 1 + edge_gap
    elseif @page_start_idx + @page_size - 1 < idx
      @_jump_to_page_at idx - edge_gap

  _highlight: (idx) =>
    highlight.remove_all 'list_selection', @swidget.buffer
    return if not idx

    offset = idx - @page_start_idx + 1
    if offset < 1 or offset > @page_size
      error 'selected item is off page'

    offset += 1 if @has_header

    lines = @swidget.buffer.lines
    pos = lines[offset].start_pos
    length = #lines[offset]
    highlight.apply 'list_selection', @swidget.buffer, pos, length

  _jump_to_page_at: (idx, select_idx=nil) =>
    start_of_last_page = #@_items - @page_size + 1
    if idx < 1
      idx = 1
    elseif idx > start_of_last_page
      idx = start_of_last_page

    @page_start_idx = idx
    @_write_page! if @swidget.showing

  prev_page: =>
    local idx
    if @selected_idx == 1
      idx = #@items
    else
      idx = math.max 1, @selected_idx - @page_size
    @_select idx

  next_page: =>
    local idx
    if @selected_idx == #@items
      idx = 1
    else
      idx = math.min #@items, @selected_idx + @page_size
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

  @property max_height:
    get: => @_max_height
    set: (val) =>
      @_max_height = val
      if @min_height > @max_height
        @_min_height = @max_height
      @_adjust_height!

  @property min_height:
    get: => @_min_height
    set: (val) =>
      @_min_height = val
      @_adjust_height!

  @property height: get: => @swidget.height

  _adjust_height: =>
    row_height = @swidget.row_height
    max_height_rows = math.floor @max_height / row_height
    min_height_rows = math.floor @min_height / row_height

    new_height_rows = #@_items + (@has_header and 1 or 0)
    new_height_rows = math.min new_height_rows, max_height_rows
    new_height_rows = math.max new_height_rows, min_height_rows

    return if @opts.never_shrink and new_height_rows < @swidget.height_rows

    @swidget.height_rows = new_height_rows

  show: =>
    @swidget\show!
    @_adjust_height!
    @_write_page!
    if not @selected_idx and @_items
      @_select @opts.reverse and #@_items or 1

  hide: => @swidget\hide!

  update: (match_text, preserve_position=false) =>
    items = self.matcher match_text
    current_idx = @selected_idx

    if @opts.reverse
      items = reversed items

    @highlight_matches_for= match_text
    @_items = items

    idx = @opts.reverse and #@_items or 1
    if preserve_position
      idx = math.min(current_idx, #@_items)

    if @swidget.showing
      @_adjust_height!
      @_write_page!
      @_select idx

  keymap:
    binding_for:
      ['cursor-up']: =>
        @select_prev!
        @opts.on_selection_change and @opts.on_selection_change @selection

      ['cursor-down']: =>
        @select_next!
        @opts.on_selection_change and @opts.on_selection_change @selection

      ['cursor-page-up']: =>
        @prev_page!
        @opts.on_selection_change and @opts.on_selection_change @selection

      ['cursor-page-down']: =>
        @next_page!
        @opts.on_selection_change and @opts.on_selection_change @selection

return ListWidget
