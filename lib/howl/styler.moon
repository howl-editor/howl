import style from howl.ui
import char_arr from howl.cdefs

style_buf = nil
style_buf_length = 0

find_style_start = (sci, pos) ->

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
  start_pos = sci\get_end_styled!
  start_line = sci\line_from_position start_pos
  start_pos = sci\position_from_line start_line
  start_pos = find_style_start sci, start_pos
  text = sci\get_text_range start_pos, end_pos

  if style_buf_length < text.size
    style_buf = char_arr(text.size)
    style_buf_length = text.size

  tokens = lexer\lex text
  pos = 0
  for token in *tokens
    style_number = style.number_for token[1], buffer
    end_token = token[2] - 1
    while pos < end_token
      style_buf[pos] = style_number
      pos += 1
  with sci
    \start_styling start_pos, 0xff
    \set_styling_ex text.size, style_buf

mark_as_styled = (sci, buffer) ->
  default_style_number = style.number_for 'default', buffer
  with sci
    start_pos = \get_end_styled!
    len = \get_length! - start_pos
    \start_styling start_pos, 0xff
    \set_styling len, default_style_number

return :style_text, :mark_as_styled
