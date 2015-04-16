-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import style, StyledText from howl.ui
append = table.insert

style.define_default 'list_header', color: '#5E5E5E', underline: true

compute_column_widths = (columns, items) ->
  widths = { num: 1 }

  if columns
    for i = 1, #columns
      header = columns[i].header or ''
      widths[i] = math.max widths[i] or 1, header and #tostring(header) or 0
      widths.num = math.max widths.num, i

  for item in *items
    if typeof(item) != 'table'
      item = { item }
    for i = 1, math.max columns and #columns or 0, #item
      cell = tostring item[i]
      widths[i] = math.max widths[i] or 1, #cell
      widths.num = math.max widths.num, i

  return widths

padding = (length) -> string.rep ' ', length

is_styled = (s) -> type(s) == 'table' and s.styles

display_str = (col) ->
  return '' if col == nil
  is_styled(col) and col or tostring(col)

(items, columns=nil) ->
  output = {}

  write = (text, style=nil) ->
    if style
      append output, StyledText text, {1, style, 1 + #text}
    else
      append output, text

  column_widths = compute_column_widths columns, items

  if columns and 0 < #[column.header for column in *columns when column.header]
    for i = 1, #columns
      header = columns[i].header
      continue unless header
      write header, 'list_header'
      pad_width = column_widths[i] - #header
      pad_width += 1 if i < #columns
      write padding pad_width

    write '\n'

  for item in *items
    if typeof(item) != 'table'
      item = { item }
    for i = 1, column_widths.num
      cell = display_str item[i]
      write cell, not is_styled(cell) and columns and columns[i] and columns[i].style
      pad_width = column_widths[i] - #tostring(cell)
      pad_width += 1 if i < column_widths.num
      write padding pad_width

    write '\n'

  return output


