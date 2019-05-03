-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

import style from howl.ui
getmetatable = getmetatable
append = table.insert

local styled_text_mt

style.define_default 'list_header', color: '#5E5E5E', underline: true

styled_text_mt = {
  __tostring: => @text,

  __serialize: => {
    text: @text
    styles: @styles
  }

  __concat: (op1, op2) ->
    text = tostring(op1) .. tostring(op2)
    return text unless typeof(op1) == "StyledText" and typeof(op2) == "StyledText"

    styles = moon.copy op1.styles
    offset = #op1.text
    i = 1

    while op2.styles[i]
      append styles, op2.styles[i] + offset
      i += 1
      append styles, op2.styles[i]
      i += 1
      if type(op2.styles[i]) == 'number'
        append styles, op2.styles[i] + offset
      else -- sub lexing table
        append styles, op2.styles[i]
      i += 1

    return setmetatable {:text, :styles}, styled_text_mt

  __type: 'StyledText',
  __len: => #@text

  __eq: (op1, op2) ->
    return false unless op1.text == op2.text
    st1, st2 = op1.styles, op2.styles
    for i = 1, #st1
      unless st1[i] == st2[i]
        el1, el2 = st1[i], st2[i]
        if type(el1) == 'table' and type(el1) == 'table' and #el1 == #el1
          for j = 1, #el1
            return unless el1[j] == el2[j]
        else
          return false

    true

  __index: (k) =>
    v = @text[k]

    if v != nil
      return v unless type(v) == 'function'
      return (_, ...) -> v @text, ...
}


compute_column_widths = (columns, items) ->
  widths = { num: 1 }

  -- compute column widths as larger of header width or specified min_width
  if columns
    for i = 1, #columns
      header = columns[i].header or ''
      widths[i] = math.max widths[i] or 1, header and tostring(header).ulen or 0, columns[i].min_width or 0
      widths.num = math.max widths.num, i

  -- grow widths to fit any items that are larger
  for item in *items
    if typeof(item) != 'table'
      item = { item }
    for i = 1, math.max columns and #columns or 0, #item
      cell = tostring item[i]
      widths[i] = math.max widths[i] or 1, cell.ulen
      widths.num = math.max widths.num, i

  return widths

padding = (length) -> string.rep ' ', length

is_styled = (s) -> type(s) == 'table' and s.styles

display_str = (col) ->
  return '' if col == nil
  t = type(col)
  return col if t == 'string'
  return col if is_styled(col)
  mt = getmetatable(col)
  if mt and mt.__tostyled
    return mt.__tostyled(col)

  tostring(col)

trim = (text, max_width) ->
  return text if tostring(text).ulen <= max_width
  max_width = max_width
  trimmed_text = tostring(text)\usub(1, max_width)

  if is_styled(text)
    -- need to trim the styles in addition to trimming the text
    trimmed_styles = {}
    styles = text.styles

    for s_idx = 1, #styles, 3
      styles_start = styles[s_idx]
      styles_end = styles[s_idx + 2]

      if styles_start > max_width
        break

      if styles_end <= max_width
        -- this style is within the trim, copy.
        append trimmed_styles, styles_start
        append trimmed_styles, styles[s_idx + 1]
        append trimmed_styles, styles_end
        continue
      if styles_start <= max_width
        -- this style is running over, trim end.
        append trimmed_styles, styles_start
        append trimmed_styles, styles[s_idx + 1]
        append trimmed_styles, max_width
        break
    return setmetatable {text: trimmed_text, styles: trimmed_styles}, styled_text_mt
  else
    return trimmed_text

for_table = (items, columns=nil, opts={}) ->
  text_parts = {}
  row_parts = {}
  styles = {}
  offset = 0
  max_width = opts.max_width

  write = (text, text_style = nil) ->
    return unless #text > 0
    append row_parts, tostring text

    if text.styles
      i = 1
      while text.styles[i]
        append styles, text.styles[i] + offset
        i += 1
        append styles, text.styles[i]
        i += 1
        if type(text.styles[i]) == 'number'
          append styles, text.styles[i] + offset
        else -- sub lexing table
          append styles, text.styles[i]
        i += 1
    elseif text_style
      append styles, offset + 1
      append styles, text_style
      append styles, offset + #text + 1

    offset += #(tostring text)

  write_cell = (cell, left_pad_width, right_pad_width, cell_style) ->
    write padding(left_pad_width), cell_style
    write cell, cell_style
    write padding(right_pad_width), cell_style

  finish_row = ->
    append text_parts, table.concat row_parts
    row_parts = {}
    append text_parts, '\n'
    offset += 1

  column_widths = compute_column_widths columns, items

  -- determine if we need to trim to max_width
  trim_column = {}  -- contains at most 1 item, key: column index, value: width
  if max_width
    remaining = max_width
    for i = 1, column_widths.num
      if i < column_widths.num
        -- non-last column - ensure we have enough space for margin(1) and suffix '[..]' (4) in case next col overflows
        if column_widths[i] + 5 <= remaining
          remaining -= column_widths[i] + 1
          continue
      else
        -- last column - only need enough space for text
        if column_widths[i] <= remaining
          break
      trim_column[i] = remaining

  -- show headers
  if columns and 0 < #[column.header for column in *columns when column.header]
    for i = 1, #columns
      header = columns[i].header
      continue unless header
      pad_width = column_widths[i] - header.ulen
      pad_width += 1 if i < #columns
      write_cell header .. padding(pad_width), 0, 0, 'list_header'

    finish_row!

  -- show rows
  for item in *items
    item = { item } if typeof(item) != 'table'

    for i = 1, column_widths.num
      cell = display_str item[i]
      cell_style = columns and columns[i] and columns[i].style
      right_align = columns and columns[i] and columns[i].align == 'right'
      right_margin = if i < column_widths.num then 1 else 0  -- space between columns

      if trim_column[i]
        width = trim_column[i]
        if tostring(cell).ulen + right_margin > trim_column[i]
          -- trim this cell as its too long
          cell = trim cell, width - 4  -- leave space for '[..]'
          write_cell cell, 0, 0, cell_style
          write_cell '[..]', 0, 0, 'comment'
        else
          -- no need to trim
          write_cell cell, 0, width - cell.ulen, cell_style
        -- always break since the trim_column is the last one
        break
      else
        left_pad_width = 0
        right_pad_width = 0
        pad_width = column_widths[i] - tostring(cell).ulen
        if right_align
          left_pad_width = pad_width
        else
          right_pad_width = pad_width

        right_pad_width += right_margin

        write_cell cell, left_pad_width, right_pad_width, cell_style

    finish_row!

  text = table.concat text_parts
  col_starts = {1, num: column_widths.num}
  for i = 2, #column_widths
    col_starts[i] = column_widths[i - 1] + col_starts[i - 1] + 1

  setmetatable({:text, :styles}, styled_text_mt), col_starts

setmetatable { :for_table },
  __call: (text, styles) =>
    if type(styles) == 'string'
      styles = {1, styles, #text + 1}

    setmetatable {:text, :styles}, styled_text_mt
