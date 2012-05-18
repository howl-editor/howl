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

styles = {}

string_to_color = (rgb) ->
  if not rgb then return nil
  r, g, b = rgb\match('^#?(%x%x)(%x%x)(%x%x)$')
  if not r then error("Invalid color specification '" .. rgb .. "'", 2)
  return tonumber(b .. g .. r, 16)

define_style = (sci, number, style) ->
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

set_for_theme = (theme) ->
  for name, def in pairs theme.styles
    style = {k,v for k,v in pairs def}
    style.number = default_style_numbers[name]
    styles[name] = style
  -- todo: define for existing scis

number_for = (style_name, buffer, sci) ->
  default_style_numbers[style_name] or default_style_numbers.default

define_styles = (sci, buffer) ->
  define_style sci, default_style_numbers.default, styles.default
  sci\style_clear_all!

  for name, style in pairs styles
    if style.number
      define_style sci, style.number, style

return :set_for_theme, :number_for, :define_styles, :string_to_color
