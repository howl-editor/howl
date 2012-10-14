default_style_numbers =
  unstyled: 0
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
  key: 16
  member: 17
  popup: 18
  default: 32
  line_number: 33
  bracelight: 34
  bracebad: 35
  controlchar: 36
  indentguide: 37
  calltip: 38

default_style_numbers[num] = name for name, num in pairs moon.copy default_style_numbers

CUSTOM_START = 19
PREDEF_START = 32
PREDEF_END = 39
STYLE_MAX = 255

styles = {}
scis = setmetatable {}, __mode: 'v'
buffer_styles = setmetatable {}, __mode: 'k'

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
    \style_set_fore number, style.color if style.color != nil
    \style_set_back number, style.background if style.background != nil
    \style_set_eolfilled number, style.eol_filled if style.eol_filled != nil
    \style_set_changeable number, not style.read_only if style.read_only != nil
    \style_set_visible number, style.visible if style.visible != nil

register_sci = (sci, default_style) ->
  set_style sci, default_style_numbers.default, default_style or styles.default
  sci\style_clear_all!

  for name, style in pairs styles
    if name != 'default'
      set_style sci, style.number, style if style.number

  append scis, sci

set_for_buffer = (sci, buffer) ->
  b_styles = get_buffer_styles buffer
  for name, style_num in pairs b_styles
    style = styles[name]
    set_style sci, style_num, style if style

define = (name, attributes) ->
  style = moon.copy attributes
  style.number = default_style_numbers[name]
  styles[name] = style

  -- redefine for existing scis

  if style.number -- default style, set for all scis
    set_style sci, style.number, style for sci in *scis
  else
    for buffer, styles in pairs buffer_styles
      if styles[name]
        set_style sci, styles[name], style for sci in *buffer.scis

next_style_number = (from_num, buffer) ->
  num = from_num + 1
  if num == PREDEF_START then return PREDEF_END + 1
  error 'Out of style numbers for ' .. tostring(buffer.title) if num > STYLE_MAX
  num

name_for = (number, buffer) ->
  default_style_numbers[number] or get_buffer_styles(buffer)[number]

number_for = (style_name, buffer) ->
  style = styles[style_name]
  if not style
    return default_style_numbers[style_name] or default_style_numbers['default']
  return style.number if style.number

  b_styles = get_buffer_styles buffer
  if b_styles[style_name] then return b_styles[style_name]

  style_num = b_styles._next_number
  set_style sci, style_num, style for sci in *buffer.scis
  b_styles[style_name] = style_num
  b_styles[style_num] = style_name
  b_styles._next_number = next_style_number style_num, buffer
  style_num

set_for_theme = (theme) ->
  define name, def for name, def in pairs theme.styles

at_pos = (buffer, pos) ->
  style_num = buffer.sci\get_style_at pos - 1
  name = default_style_numbers[style_num] or get_buffer_styles(buffer)[style_num]
  name, styles[name]

return setmetatable {
  :set_for_theme
  :number_for
  :name_for
  :register_sci
  :set_for_buffer
  :define
  :at_pos
}, __index: styles
