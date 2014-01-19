ffi = require 'ffi'
import style from howl.ui
import char_arr from howl.cdefs

style_number_for = style.number_for
style_name_for = style.name_for
ffi_fill = ffi.fill
string_byte = string.byte
whitespace = style_number_for 'whitespace'

style_buf = nil
style_buf_length = 0

get_styling_start_pos = (sci) ->
  -- so where to begin?
  pos = sci\get_end_styled!
  line = sci\line_from_position pos
  line = math.max(0, line - 1)

  while line > 5 -- don't bother with smarts if were so close to the beginning of doc

    -- we could just start at the beginning of the line?
    pos = sci\position_from_line line

    -- hmm, unless we're in the middle of something of course..
    -- but if the newline before is styled with whitespace, we're presumably OK
    -- though since multiline lexing would just style everything until the end with
    -- the same non-whitespace style, including newlines
    cur_style = sci\get_style_at pos
    if cur_style != 0 -- 0 == unstyled, means we're probably editing it right now
      nl_pos = sci\get_line_end_position line - 1
      nl_style = sci\get_style_at nl_pos
      return pos if nl_style == whitespace

    -- back up a line
    line -= 1

  -- just start from the beginning
  0

apply_tokens = (buffer, style_buf, offset, tokens, base_style, gap_style_number) ->
  last_pos = offset + 1

  for idx = 1, #tokens, 3
    pos = tokens[idx]
    style_name = tokens[idx + 1]
    stop_pos = tokens[idx + 2]

    if type(stop_pos) == 'number'
      style_number = style_number_for style_name, buffer, base_style
      pos += offset
      stop_pos += offset

      ffi_fill style_buf + last_pos, pos - last_pos, gap_style_number

      while pos < stop_pos
        style_buf[pos] = style_number
        pos += 1

      last_pos = stop_pos

    else -- embedded
      op, mode_spec = style_name, stop_pos
      sub_base = mode_spec\match '[^|]*|(.+)'
      sub_gap_number = style_number_for sub_base, buffer
      last_pos = apply_tokens buffer, style_buf, pos - 1, op, sub_base, sub_gap_number

  last_pos, gap_style_number

apply = (buffer, start_pos, end_pos, tokens) ->
  last_styled_pos = tokens[#tokens]
  return unless last_styled_pos

  sci = buffer.sci
  default_style_number = style_number_for 'default', buffer

  length = end_pos - start_pos + 1
  return 0 unless length > 0

  if style_buf_length < length + 1 -- we'll use one-based indexes below, hence the + 1
    style_buf = char_arr(length + 1)
    style_buf_length = length + 1

  last_pos, gap_style_number = apply_tokens buffer, style_buf, 0, tokens, base, default_style_number

  -- fill any unstyled tail with default
  fill_count = length - last_pos + 1
  if fill_count > 0
    ffi_fill style_buf + last_pos, fill_count, gap_style_number

  with sci
    \start_styling start_pos - 1, 0xff
    \set_styling_ex length, style_buf + 1

style_text = (buffer, end_pos, lexer) ->
  start_pos = get_styling_start_pos buffer.sci
  text = buffer.sci\get_text_range start_pos, end_pos
  apply buffer, start_pos + 1, start_pos + #text, lexer(text)

reverse = (buffer, start_pos, end_pos) ->
  default_style_number = style_number_for 'default', buffer
  style_bytes = buffer.sci\get_styled_text start_pos - 1, end_pos
  styles = {}

  cur_style = -1
  c_index = 1

  for i = 1, #style_bytes, 2
    style_num = style_bytes\byte(i + 1)
    if style_num != cur_style
      styles[#styles + 1] = c_index if #styles > 0 and cur_style != default_style_number -- mark end pos
      if style_num != default_style_number
        styles[#styles + 1] = c_index
        styles[#styles + 1] = style_name_for style_num, buffer

    c_index += 1
    cur_style = style_num

  if #styles > 0 and cur_style != default_style_number -- mark end pos
    styles[#styles + 1] = c_index

  styles

clear_styling = (sci, buffer) ->
  default_style_number = style.number_for 'default', buffer
  with sci
    end_pos = \get_end_styled!
    \start_styling 0, 0xff
    \set_styling end_pos, default_style_number

return :apply, :style_text, :clear_styling, :reverse
