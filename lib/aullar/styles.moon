-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Pango = require 'ljglibs.pango'
AttrList = Pango.AttrList
Attribute = Pango.Attribute
Color = Pango.Color
append = table.insert
ffi = require 'ffi'


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

  if def.background
    c = Color def.background
    append attrs, Attribute.Background(c.red, c.green, c.blue)

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
    append attrs, Attribute.LetterSpacing(def.letter_spacing * 1024)

  if def.font
    font = def.font
    append attrs, Attribute.Family(font.family) if font.family
    append attrs, Attribute.Style(Pango.STYLE_ITALIC) if font.italic
    append attrs, Attribute.Weight(Pango.WEIGHT_BOLD) if font.bold
    append attrs, Attribute.Size(font.size * 1024) if font.size

  attrs

define = (name, def) ->
  styles[name] = def

apply = (list, name, start_index = Pango.ATTR_INDEX_FROM_TEXT_BEGINNING, end_index = Pango.ATTR_INDEX_TO_TEXT_END) ->
  def = styles[name]
  return unless def

  attrs = attributes[name]
  unless attrs
    attrs = create_attributes def
    attributes[name] = attrs

  for attr in *attrs
    attr = attr\copy!
    attr.start_index = start_index
    attr.end_index = end_index
    list\insert_before attr

:define, :apply
