ffi = require 'ffi'
import style from howl.ui
import char_arr from howl.cdefs

style_buf = nil
style_buf_length = 0

get_styling_start_pos = (sci) ->
  pos = sci\get_end_styled!
  start_line = sci\line_from_position pos
  pos = sci\position_from_line start_line

  -- find first differing style from current pos
  cur_style = sci\get_style_at pos
  while pos > 0
    pos -= 1
    s = sci\get_style_at(pos)
    if s != cur_style
      cur_style = s
      break

  -- and follow it back to the first pos with the same style
  while pos > 0
    pos -= 1
    s = sci\get_style_at(pos)
    if s != cur_style
      return pos + 1

  return pos

style_text = (sci, buffer, end_pos, lexer) ->
  start_pos = get_styling_start_pos sci
  text = sci\get_text_range start_pos, end_pos
  default_style_number = style.number_for 'default', buffer

  size = text.size + 1 -- we'll use one-based indexes below, hence the +1
  if style_buf_length < size
    style_buf = char_arr(size)
    style_buf_length = size

  tokens = lexer text
  last_pos = 1
  for idx = 1, #tokens, 3
    pos = tokens[idx]
    style_number = style.number_for tokens[idx + 1], buffer
    end_pos = tokens[idx + 2]
    ffi.fill style_buf + last_pos, pos - last_pos, default_style_number

    while pos < end_pos
      style_buf[pos] = style_number
      pos += 1

    last_pos = end_pos

  ffi.fill style_buf + last_pos, size - last_pos, default_style_number

  with sci
    \start_styling start_pos, 0xff
    \set_styling_ex text.size, style_buf + 1

mark_as_styled = (sci, buffer) ->
  default_style_number = style.number_for 'default', buffer
  with sci
    start_pos = \get_end_styled!
    len = \get_length! - start_pos
    \start_styling start_pos, 0xff
    \set_styling len, default_style_number

return :style_text, :mark_as_styled
