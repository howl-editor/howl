import PropertyObject from vilu.aux.moon
import style from vilu.ui

style.define 'list_header', color: '#5E5E5E', underline: true

calculate_column_widths = (items, headers) ->
    widths = {}

    for item in *items
      if type(item) != 'table' then return nil
      for i, col in ipairs item
        widths[i] = math.max(widths[i] or 0, #tostring col)

    if headers
      for i, col in ipairs headers
        widths[i] = math.max(widths[i] or 0, #tostring col)

    widths

column_padding = (text, column, widths) ->
  return '' if not widths or column == #widths
  string.rep ' ', (widths[column] + 1) - #text

class List extends PropertyObject
  column_styles: { 'string', 'comment', 'operator' }

  new: (items, headers) =>
    @items = items
    if headers
      @headers = type(headers) == 'table' and headers or { headers }
    super!

  @property items:
    get: => @_items
    set: (items) =>
      @_items = items
      @_widths = nil

  @property headers:
    get: => @_headers
    set: (headers) =>
      @_headers = headers
      @_widths = nil

  render: (buffer, pos, start_item, end_item) =>
    start_item = start_item or 1
    end_item = end_item or #@items

    if not @_widths
      @_widths = calculate_column_widths @items, @headers
      @_multi_column = @_widths != nil

    if @headers
      for column, header in ipairs @headers
        padding = column_padding header, column, @_widths
        pos = buffer\insert header, pos, 'list_header'
        pos = buffer\insert padding, pos

      pos = buffer\insert '\n', pos

    for row = start_item, end_item
      item = @items[row]
      if @_multi_column
        for column, field in ipairs item
          padding = column_padding field, column, @_widths
          pos = buffer\insert field, pos, @_column_style item, row, column
          pos = buffer\insert padding, pos
      else
        pos = buffer\insert item, pos, @_column_style item, row, 1

      pos = buffer\insert '\n', pos

    pos

  __len: => #@items

  _column_style: (item, row, column) =>
    if callable @column_styles then return self.column_styles(item, row, column)
    @column_styles[column]

return List
