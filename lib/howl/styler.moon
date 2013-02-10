ffi = require 'ffi'
import style from howl.ui
import char_arr from howl.cdefs

style_buf = nil
style_buf_length = 0

get_styling_start_pos = (sci) ->
  -- so where to begin?
  pos = sci\get_end_styled!
  start_line = sci\line_from_position pos

  -- at the start already, or close enough - a safe start from the beginning
  return 0 if start_line == 0 or pos < 10

  -- we could just start at the beginning of the line?
  pos = sci\position_from_line start_line

  -- hmm, unless we're in the middle of something of course..
  -- but if the actual newline is styled differently than the pos before,
  -- we're presumably OK though since multiline lexing would just style
  -- everything until the end with the same style
  nl_pos = sci\get_line_end_position start_line - 1
  nl_style = sci\get_style_at nl_pos
  before_nl_style = sci\get_style_at nl_pos - 1
  return pos if nl_style != before_nl_style

  -- OK, fine. we're now in unknown territory, so back up until the last
  -- style change in order to get some perspective
  for pos = nl_pos - 2, 0, -1
    cur_style = sci\get_style_at pos
    return pos + 1 if cur_style != nl_style

  -- and after all this we're now back square zero after all, yay!
  0

style_text = (sci, buffer, end_pos, lexer) ->
  start_pos = get_styling_start_pos sci
  text = sci\get_text_range start_pos, end_pos
  default_style_number = style.number_for 'default', buffer

  size = text.size + 1 -- we'll use one-based indexes below, hence the + 1
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

return :style_text
