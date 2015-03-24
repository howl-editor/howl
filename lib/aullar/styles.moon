-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Pango = require 'ljglibs.pango'
AttrList = Pango.AttrList
Attribute = Pango.Attribute
SCALE = Pango.SCALE
Color = Pango.Color
append = table.insert
ffi = require 'ffi'
{:copy} = moon

styles = {}
attributes = {}

underline_options = {
  [true]: Pango.UNDERLINE_SINGLE,
  single: Pango.UNDERLINE_SINGLE,
  double: Pango.UNDERLINE_DOUBLE,
  low: Pango.UNDERLINE_LOW,
  error: Pango.UNDERLINE_ERROR
}

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
    append attrs, Attribute.Size(font.size * SCALE) if font.size

  attrs

define = (name, definition) ->
  error "Missing argument #1 (name)", 2 unless name
  error "Missing argument #2 (definition)", 2 unless definition

  if type(definition) != 'string'
    definition = copy definition
    definition.name = name

  styles[name] = definition
  attributes[name] = nil

define_default = (name, attributes) ->
  define name, attributes unless styles[name]

def_for = (name) ->
  def = styles[name]
  while type(def) == 'string'
    def = styles[def]

  if not def
    base, ext = name\match '^([^:]+):(%S+)$'
    if base
      base, ext = styles[base], styles[ext]

      if base
        return base unless ext

        def = font: copy(base.font or {})
        for k in *{
          'background',
          'color',
          'underline',
          'letter_spacing',
          'strike_through'
        }
          def[k] = ext[k] or base[k]

        if ext.font
          for k in *{ 'family', 'italic', 'bold', 'size' }
            def.font[k] or= ext.font[k]

  def

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

get_attributes = (styling, opts = {}) ->
  list = AttrList()
  return list unless styling

  for i = 1, #styling, 3
    apply list, styling[i + 1], styling[i] - 1, styling[i + 2] - 1, opts

  list

:define, :define_default, :apply, :create_attributes, :get_attributes, :def_for
