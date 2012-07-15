default_style_numbers =
  nothing: 0
  whitespace: 1
  comment: 2
  string: 3
  number: 4
  keyword: 5
  identifier: 6
  operator: 7
  error: 8
  preproc: 9
  constant: 10
  variable: 11
  ['function']: 12
  class: 13
  type: 14
  longstring: 15
  default: 32
  line_number: 33
  bracelight: 34
  bracebad: 35
  controlchar: 36
  indentguide: 37
  calltip: 38

CUSTOM_START = 16
PREDEF_START = 32
PREDEF_END = 39
STYLE_MAX = 255

styles = {}
buffer_styles = setmetatable {}, __mode: 'k'

string_to_color = (rgb) ->
  if not rgb then return nil
  r, g, b = rgb\match('^#?(%x%x)(%x%x)(%x%x)$')
  if not r then error("Invalid color specification '" .. rgb .. "'", 2)
  return tonumber(b .. g .. r, 16)

get_buffer_styles = (buffer) ->
  b_styles = buffer_styles[buffer]
  if b_styles then return b_styles
  b_styles = _next_number: CUSTOM_START
  buffer_styles[buffer] = b_styles
  b_styles

set_style = (sci, number, style) ->
  font = style.font
  with sci
    if font
      \style_set_font number, font.name if font.name != nil
      \style_set_size number, font.size if font.size != nil
      \style_set_bold number, font.bold if font.bold != nil
      \style_set_italic number, font.italic if font.italic != nil
      \style_set_weight number, font.weight if font.weight != nil

    \style_set_underline number, style.underline if style.underline != nil
    \style_set_fore number, string_to_color style.color if style.color != nil
    \style_set_back number, string_to_color style.background if style.background != nil
    \style_set_eolfilled number, style.eol_filled if style.eol_filled != nil
    \style_set_changeable number, not style.read_only if style.read_only != nil
    \style_set_visible number, style.visible if style.visible != nil

register_sci = (sci, buffer) ->
  set_style sci, default_style_numbers.default, styles.default
  sci\style_clear_all!

  for name, style in pairs styles
      set_style sci, style.number, style if style.number

set_for_buffer = (sci, buffer) ->
  b_styles = get_buffer_styles buffer
  for name, style_num in pairs b_styles
    style = styles[name]
    set_style sci, style_num, style if style

define = (name, attributes) ->
  style = moon.copy attributes
  style.number = default_style_numbers[name]
  styles[name] = style
  -- todo: redefine for existing scis

next_style_number = (from_num, buffer) ->
  num = from_num + 1
  if num == PREDEF_START then return PREDEF_END + 1
  error 'Out of style numbers for ' .. tostring(buffer.title) if num > STYLE_MAX
  num

number_for = (style_name, buffer, sci) ->
  style = styles[style_name]
  if not style
    return default_style_numbers[style_name] or default_style_numbers['default']
  return style.number if style.number

  b_styles = get_buffer_styles buffer
  if b_styles[style_name] then return b_styles[style_name]

  style_num = b_styles._next_number
  set_style sci, style_num, style
  b_styles[style_name] = style_num
  b_styles._next_number = next_style_number style_num, buffer
  style_num

set_for_theme = (theme) ->
  define name, def for name, def in pairs theme.styles

return setmetatable {
  :set_for_theme
  :number_for
  :register_sci
  :set_for_buffer
  :define
  :string_to_color
}, __index: styles
