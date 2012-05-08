import style from vilu.ui

ffi = require('ffi')
C = ffi.C
cbuf = ffi.typeof('char[?]')
style_buf = nil
style_buf_length = 0

style_text = (sci, buffer, end_pos, lexer) ->
  start_pos = sci\get_end_styled!
  start_line = sci\line_from_position start_pos
  start_pos = sci\position_from_line start_line
  text = sci\get_text_range start_pos, end_pos
  style_buf = cbuf(#text) if style_buf_length < #text
  tokens = lexer\lex text
  pos = 0
  for token in *tokens
    style_number = style.number_for token[1], buffer, sci
    end_pos = token[2] - 1
    while pos < end_pos
      style_buf[pos] = style_number
      pos += 1
  with sci
    \start_styling start_pos, 0xff
    \set_styling_ex #text, style_buf

return :style_text
