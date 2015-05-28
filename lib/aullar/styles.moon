-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

config = require 'aullar.config'
Pango = require 'ljglibs.pango'
{:AttrList, :Attribute, :SCALE, :Color} = Pango
append = table.insert
ffi = require 'ffi'
{:cast} = ffi
{:copy} = moon

styles = {
  default: {}
}
attributes = {}

underline_options = {
  [true]: Pango.UNDERLINE_SINGLE,
  single: Pango.UNDERLINE_SINGLE,
  double: Pango.UNDERLINE_DOUBLE,
  low: Pango.UNDERLINE_LOW,
  error: Pango.UNDERLINE_ERROR
}

font_size_deltas = {
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

pango_attr_p = ffi.typeof('PangoAttribute *')
attr_ptr = (a) -> cast pango_attr_p, a

get_font_size = (v) ->
  return v unless type(v) == 'string'
  delta = font_size_deltas[v]
  error "Invalid font size specification '#{v}'", 2 unless delta
  config.view_font_size + delta

create_attributes = (def) ->
  attrs = {}

  if def.color
    c = Color def.color
    append attrs, Attribute.Foreground(c.red, c.green, c.blue)

  if def.strike_through
    append attrs, Attribute.Strikethrough(true)
    if type(def.strike_through) == 'string'
      c = Color def.strike_through
      append attrs, Attribute.StrikethroughColor(c.red, c.green, c.blue)

  if def.underline
    vals = { def.underline }
    if type(def.underline) == 'string'
      vals = [v for v in def.underline\gmatch '%S+']

    style = underline_options[vals[1]]
    if style
      append attrs, Attribute.Underline(style) if style

      if #vals > 1
        c = Color vals[2]
        append attrs, Attribute.UnderlineColor(c.red, c.green, c.blue)

  if def.letter_spacing
    append attrs, Attribute.LetterSpacing(def.letter_spacing * SCALE)

  if def.font
    font = def.font
    append attrs, Attribute.Family(font.family) if font.family
    append attrs, Attribute.Style(Pango.STYLE_ITALIC) if font.italic
    append attrs, Attribute.Weight(Pango.WEIGHT_BOLD) if font.bold
    append attrs, Attribute.Size(get_font_size(font.size) * SCALE) if font.size

  attrs

define = (name, definition) ->
  error "Missing argument #1 (name)", 2 unless name
  error "Missing argument #2 (definition)", 2 unless definition

  if type(definition) != 'string'
    definition = copy definition
    definition.name = name

  styles[name] = definition

  if name == 'default'
    attributes = {}
  else
    attributes[name] = nil
    for k in pairs attributes
      attributes[k] = nil if k\match "^#{name}:"

define_default = (name, attributes) ->
  define name, attributes unless styles[name]

def_for = (name) ->
  base = styles.default
  def = styles[name]

  while type(def) == 'string'
    def = styles[def]

  if not def
    -- look for sub styling (base:style)
    sub_base, ext = name\match '^([^:]+):(%S+)$'
    if sub_base
      base, def = styles[sub_base] or base, styles[ext]

  return base unless def

  live = name: name, font: base.font
  for k in *{
    'background',
    'color',
    'underline',
    'letter_spacing',
    'strike_through'
  }
    live[k] = def[k] or base[k]

  if def.font
    live.font = copy(live.font or {})
    for k in *{ 'family', 'italic', 'bold', 'size' }
      if def.font[k]
        live.font[k] = def.font[k]

  live

_exclude_attribute_list = {
  [tonumber Pango.ATTR_FOREGROUND]: 'color'
}

_exclude_attribute = (attr, exclude) ->
  attr_type = tonumber attr_ptr(attr).klass.type
  key = _exclude_attribute_list[attr_type]
  key and exclude[key]

apply = (list, name, start_index = Pango.ATTR_INDEX_FROM_TEXT_BEGINNING, end_index = Pango.ATTR_INDEX_TO_TEXT_END, opts = {}) ->
  attrs = attributes[name]
  exclude = opts.exclude

  unless attrs
    def = def_for name
    return unless def

    attrs = create_attributes def, opts
    attributes[name] = attrs

  for attr in *attrs
    continue if exclude and _exclude_attribute attr, exclude
    attr = attr\copy!
    attr.start_index = start_index
    attr.end_index = end_index
    list\insert_before attr

get_attributes = (styling, end_offset, opts = {}) ->
  list = AttrList()
  return list unless styling

  last_pos_styled = 0

  for i = 1, #styling, 3
    start_index = styling[i] - 1
    end_index = styling[i + 2] - 1
    style_name = styling[i + 1]

    if start_index > last_pos_styled
      apply list, 'default', last_pos_styled, start_index - 1, opts

    apply list, style_name, start_index, end_index, opts

  if last_pos_styled < end_offset
    apply list, 'default', last_pos_styled, end_offset, opts

  list

:define, :define_default, :apply, :create_attributes, :get_attributes, :def_for
