import PropertyObject from vilu.aux.moon
import style, highlight from vilu.ui

style.define 'list_header', color: '#5E5E5E', underline: true

highlight.define 'list_selection', {
  style: highlight.ROUNDBOX,
  color: '#ffffff'
  outline_alpha: 100
}

calculate_column_widths = (items, headers) ->
    widths = {}

    for item in *items
      if type(item) != 'table' then return nil
      for i, col in ipairs item
        widths[i] = math.max(widths[i] or 0, #tostring col)

    if headers and #headers > 0
      for i, col in ipairs headers
        widths[i] = math.max(widths[i] or 0, #tostring col)

    widths

column_padding = (text, column, widths) ->
  return '' if not widths or column == #widths
  string.rep ' ', (widths[column] + 1) - #text

class List extends PropertyObject
  column_styles: { 'string', 'comment', 'operator' }

  new: (buffer, pos) =>
    @buffer = buffer
    @start_pos = pos
    @max_height = nil
    @offset = 1
    @selection_enabled = false
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
    get: =>
      @_sel_row and @items[@_sel_row] or nil

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

  scroll_to: (row) =>
    error 'List is not shown', 2 if not @end_pos

    total = #@items
    return if not @max_height or total < @max_height
    @offset = row
    if @offset < 1
      @offset = 1
    elseif @offset > total or total - @offset < @max_height
      @offset = total - @max_height + 1

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

    if row < @offset or row > @end_item
      offset = row - @limit + 1
      @scroll_to math.max offset, 1

    @select row

  select_next: =>
    row = @_sel_row + 1
    row = 1 if row > #@items

    if row < @offset or row > @end_item
      @scroll_to row

    @select row

  select: (row) =>
    error 'Selection is not enabled', 2 if not @selection_enabled
    if row < 1 or row > #@items
      error 'Row "' .. row .. '" out of range', 2

    @_sel_row = row
    highlight.remove_all 'list_selection', @buffer

    if row >= @offset and row <= @end_item
      lines = @buffer.lines
      start_line = lines\nr_at_pos @start_pos
      sel_line = row - @offset + 1
      sel_line += 1 if @headers and #@headers > 0
      pos = lines\pos_for sel_line
      length = #lines[sel_line]
      highlight.apply 'list_selection', @buffer, pos, length

  show: =>
    @clear!

    total = #@items
    @end_item = if @max_height
        math.min @max_height + @offset - 1, total
      else
        total

    pos = @start_pos
    buffer = @buffer

    if not @_widths
      @_widths = calculate_column_widths @items, @headers
      @_multi_column = @_widths != nil

    if @headers and #@headers > 0
      for column, header in ipairs @headers
        padding = column_padding header, column, @_widths
        pos = buffer\insert header, pos, 'list_header'
        pos = buffer\insert padding, pos

      pos = buffer\insert '\n', pos

    for row = @offset, @end_item
      item = @items[row]
      start_pos = pos
      if @_multi_column
        for column, field in ipairs item
          padding = column_padding field, column, @_widths
          pos = buffer\insert field, pos, @_column_style item, row, column
          pos = buffer\insert padding, pos
      else
        pos = buffer\insert item, pos, @_column_style item, row, 1

      pos = buffer\insert '\n', pos

    @nr_shown = @end_item - @offset + 1

    if @nr_shown < total
      info = string.format '[..] (showing %d - %d out of %d)\n',
        @offset, @end_item, total
      pos = @buffer\insert info, pos, 'comment'

    @_sel_row = @offset if not @_sel_row and @selection_enabled
    @select @_sel_row if @_sel_row

    @end_pos = pos
    pos

  __len: => #@items

  _column_style: (item, row, column) =>
    if callable @column_styles then return self.column_styles(item, row, column)
    @column_styles[column]

return List
