import PropertyObject from lunar.aux.moon
import style, highlight from lunar.ui

style.define 'list_header', color: '#5E5E5E', underline: true
style.define 'list_caption', {}

highlight.define_default 'list_selection', {
  style: highlight.ROUNDBOX,
  color: '#ffffff'
  outline_alpha: 100
}

calculate_column_widths = (items, headers) ->
    widths = {}

    for item in *items
      item = { item } if type(item) != 'table'
      for i, col in ipairs item
        widths[i] = math.max(widths[i] or 0, #tostring(col))

    if headers and #headers > 0
      for i, col in ipairs headers
        widths[i] = math.max(widths[i] or 0, #tostring(col))

    widths

column_padding = (text, column, widths) ->
  return '' if column == #widths
  string.rep ' ', (widths[column] - #text) + 1

line_count = (s) ->
  count = -1
  init = 0

  while init
    count += 1
    _, init = s\find '\n', init + 1, true

  count

class List extends PropertyObject
  column_styles: { 'string', 'comment', 'operator' }

  new: (buffer, pos) =>
    @buffer = buffer
    @start_pos = pos
    @max_height = nil
    @offset = 1
    @selection_enabled = false
    @trailing_newline = true
    super!

  @property items:
    get: => @_items
    set: (items) =>
      @_items = items or {}
      @_widths = nil

  @property headers:
    get: => @_headers
    set: (headers) =>
      @_headers = headers or {}
      @_widths = nil

  @property selection:
    get: => @_sel_row and @items[@_sel_row] or nil
    set: (sel_item) =>
      for i, item in ipairs @items
        if sel_item == item
          @select i
          return

      error 'Could not set selection: ' .. tostring(sel_item) .. ' was not found', 2

  @property limit:
    get: =>
      return nil if not @max_height
      height = @max_height
      height -= 1 if @headers and #@headers > 0
      height

  clear: =>
    if @end_pos
      @buffer\delete @start_pos, @end_pos - @start_pos
      @end_pos = nil

  @property showing:
    get: => @end_pos != nil

  scroll_to: (row) =>
    error 'List is not shown', 2 if not @showing

    total = #@items
    max_item_lines = (@last_shown - @offset) + 1
    @offset = row
    if @offset < 1
      @offset = 1
    elseif @offset > total or (total - @offset) + 1 < max_item_lines
      @offset = (total - max_item_lines) + 1

    @show!
    @select row if @selection_enabled

  prev_page: =>
    return if not @max_height
    row = @offset - @max_height
    row = #@items if row < 1
    @scroll_to row

  next_page: =>
    return if not @max_height
    row = @offset + @max_height
    row = 1 if row > #@items
    @scroll_to row

  select_prev: =>
    row = @_sel_row - 1
    row = #@items if row < 1

    if row < @offset or row > @last_shown
      offset = row - @limit + 1
      @scroll_to math.max offset, 1

    @select row

  select_next: =>
    row = @_sel_row + 1
    row = 1 if row > #@items

    if row < @offset or row > @last_shown
      @scroll_to row

    @select row

  select: (row) =>
    error 'Selection is not enabled', 2 if not @selection_enabled
    if row < 1 or row > #@items
      error 'Row "' .. row .. '" out of range', 2

    @_sel_row = row

    if @showing
      highlight.remove_all 'list_selection', @buffer

      if row >= @offset and row <= @last_shown
        lines = @buffer.lines
        start_line = lines\at_pos(@item_start_pos).nr
        sel_line = start_line + (row - @offset)
        pos = lines[sel_line].start_pos
        length = #lines[sel_line]
        highlight.apply 'list_selection', @buffer, pos, length
      else
        @scroll_to row

  show: =>
    @clear!

    total = #@items
    lines_left = @max_height or math.huge
    pos = @start_pos
    buffer = @buffer

    if not @_widths
      @_widths = calculate_column_widths @items, @headers
      @_multi_column = #@_widths > 1

    if @caption and lines_left > 0
      cap = @caption .. '\n'
      pos = buffer\insert cap, pos, 'list_caption'
      lines_left -= line_count cap

    if @headers and #@headers > 0 and lines_left > 0
      for column, header in ipairs @headers
        padding = column_padding header, column, @_widths
        pos = buffer\insert header, pos, 'list_header'
        pos = buffer\insert padding, pos

      pos = buffer\insert '\n', pos
      lines_left -= 1

    @last_shown = if total > lines_left
        math.min @offset + lines_left - 1, total
      else
       total

    @item_start_pos = pos
    total_length = 0
    total_length += width for width in *@_widths
    total_length += #@_widths if @_multi_column
    for row = @offset, @last_shown
      item = @items[row]
      start_pos = pos
      if @_multi_column
        for column, field in ipairs item
          padding = column_padding field, column, @_widths
          pos = buffer\insert tostring(field), pos, @_column_style item, row, column
          pos = buffer\insert padding, pos
      else
        pos = buffer\insert tostring(item), pos, @_column_style item, row, 1

      if @selection_enabled
        extra_spaces = total_length - (pos - start_pos)
        if extra_spaces > 0
          padding = string.rep ' ', extra_spaces
          pos = buffer\insert padding, pos

      if row != @last_shown
        pos = buffer\insert '\n', pos

    @nr_shown = @last_shown - @offset + 1

    if @nr_shown < total and lines_left > 0
      info = string.format '\n[..] (showing %d - %d out of %d)',
        @offset, @last_shown, total
      pos = @buffer\insert info, pos, 'comment'

    pos = @buffer\insert '\n', pos if @trailing_newline
    @_sel_row = @offset if not @_sel_row and @selection_enabled
    @end_pos = pos

    @select @_sel_row if @_sel_row and #@items > 0

    pos

  @meta {
    __len: => #@items
  }

  _column_style: (item, row, column) =>
    if callable @column_styles then return self.column_styles(item, row, column)
    @column_styles[column]

return List
