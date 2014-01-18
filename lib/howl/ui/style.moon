-- Copyright 2012-2013 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE.md)

import config from howl

default_style_numbers = {
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
  'function': 12
  class: 13
  type: 14
  longstring: 15
  key: 16
  member: 17
  popup: 18
  symbol: 19
  global: 20
  fdecl: 21
  regex: 22

  default: 32
  line_number: 33
  bracelight: 34
  bracebad: 35
  controlchar: 36
  indentguide: 37
  calltip: 38
}

default_style_numbers[num] = name for name, num in pairs moon.copy default_style_numbers

CUSTOM_START = 23
PREDEF_START = 32
PREDEF_END = 39
STYLE_MAX = 255

styles = {}
scis = setmetatable {}, __mode: 'k'
buffer_styles = setmetatable {}, __mode: 'k'

size_offsets = {
  'xx-small': -4
  'x-small': -3
  smaller: -2
  small: -1
  medium: 0
  large: 1
  larger: 2
  'x-large': 3
  'xx-large': 4
}

get_font_size = (def) ->
  size = config.font_size
  if def
    delta = size_offsets[def]
    error "Invalid font size specification '#{def}'", 3 unless delta
    size += delta

  size

get_buffer_styles = (buffer) ->
  b_styles = buffer_styles[buffer]
  if b_styles then return b_styles
  b_styles = _next_number: CUSTOM_START
  buffer_styles[buffer] = b_styles
  b_styles

set_style = (sci, number, style, is_default) ->
  font = style.font or {}
  default = is_default and style or styles[scis[sci]] or styles.default
  error "sci instance is not registered: #{sci}", 2 unless default
  default_font = default.font or {}
  one_of = (a, b) -> a != nil and a or b

  with sci
    \style_set_font number, config.font
    \style_set_size number, get_font_size font.size
    \style_set_bold number, one_of(font.bold, default_font.bold)
    \style_set_italic number, one_of(font.italic, default_font.italic)
    \style_set_underline number, one_of(style.underline, default.underline)
    \style_set_fore number, one_of(style.color, default.color)
    \style_set_back number, one_of(style.background, default.background)
    \style_set_eolfilled number, one_of(style.eol_filled, default.eol_filled)
    \style_set_changeable number, not (one_of(style.read_only, default.read_only))
    \style_set_visible number, not (one_of(style.visible, default.visible) == false)

register_sci = (sci, default_style = 'default') ->
  error "Invalid default style '#{default_style}'", 2 unless styles[default_style]
  set_style sci, default_style_numbers.default, styles[default_style], true
  scis[sci] = default_style
  sci\style_clear_all!

  for name, style in pairs styles
    if style != default_style and style.number != default_style_numbers.default
      set_style sci, style.number, style if style.number

set_for_buffer = (sci, buffer) ->
  b_styles = get_buffer_styles buffer
  for name, style_num in pairs b_styles
    style = styles[name]
    set_style sci, style_num, style if style

is_extended = (style_name) ->
  style_name\contains ':'

define_extended = (style_name) ->
  base, ext = style_name\match '^([^:]+):(%S+)$'
  error "Not an extended style: #{style_name}", 2 unless base
  if styles[base] and styles[ext]
    def = moon.copy styles[base]
    def[k] = v for k,v in pairs styles[ext]
    def.number = nil
    styles[style_name] = def
    def

rebase_on = (style_name, definition, sci) ->
  style_number = default_style_numbers.default

  set_style sci, style_number, definition
  sci\style_clear_all!

  for name, style in pairs styles
    if name != style_name and style.number
      set_style sci, style.number, style

  for buffer, b_styles in pairs buffer_styles
    for b_sci in *buffer.scis
      if b_sci == sci
        for name, number in pairs b_styles
          style = styles[name]
          if style
            define_extended name if is_extended name
            set_style sci, number, styles[name]

define = (name, definition) ->
  error "Missing argument #1 (name)", 2 unless name
  error "Missing argument #2 (definition)", 2 unless definition

  if type(definition) == 'string' -- style alias
    styles[name] = definition
    return

  style = moon.copy definition
  style.number = default_style_numbers[name]
  styles[name] = style

  -- redefine for existing scis
  affected_scis = {} -- (sci -> style number)

  if style.number then -- default style, affects all scis
    affected_scis[sci] = style.number for sci in pairs scis
  else -- find scis for buffers with this style
    for buffer, b_styles in pairs buffer_styles
      if b_styles[name]
        affected_scis[sci] = b_styles[name] for sci in *buffer.scis

  for sci, style_number in pairs affected_scis
    if name == scis[sci] -- redefining the default style for the sci
      rebase_on name, style, sci
    else
      set_style sci, style_number, style

  unless is_extended name
    extended_styles = [n for n in pairs styles when is_extended(n) and n\contains(name)]
    for n in *extended_styles
      define n, define_extended n

  style

define_default = (name, attributes) ->
  define name, attributes unless styles[name]

next_style_number = (from_num, buffer) ->
  num = from_num + 1
  if num == PREDEF_START then return PREDEF_END + 1
  error('Out of style numbers for ' .. buffer.title) if num > STYLE_MAX
  num

name_for = (number, buffer) ->
  default_style_numbers[number] or get_buffer_styles(buffer)[number]

number_for = (style_name, buffer, base) ->
  -- resolve any style aliases
  while type(styles[style_name]) == 'string'
    style_name = styles[style_name]

  if base
    style_name = "#{base}:#{style_name}"
  else
    base = style_name\match ':(.+)$'

  style = styles[style_name]

  if not style
    if base
      style = define_extended(style_name)
      if not style
        style = styles[base]
        style_name = base
    else
      return default_style_numbers[style_name] or default_style_numbers.default

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
  -- copy all theme style definitions
  for name, definition in pairs theme.styles
    style = moon.copy definition
    style.number = default_style_numbers[name]
    styles[name] = style

  -- and rebase all existing scis
  rebase_on default_style, styles[default_style], sci for sci, default_style in pairs scis

at_pos = (buffer, pos) ->
  b_pos = buffer\byte_offset pos
  style_num = buffer.sci\get_style_at b_pos - 1
  name = default_style_numbers[style_num] or get_buffer_styles(buffer)[style_num]
  name, styles[name]

-- alias some default styles
define 'symbol', 'key'
define 'global', 'member'
define 'regex', 'string'

return setmetatable {
  :set_for_theme
  :number_for
  :name_for
  :register_sci
  :set_for_buffer
  :define
  :define_default
  :at_pos
}, __index: styles
