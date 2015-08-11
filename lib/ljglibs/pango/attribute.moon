-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

ffi = require 'ffi'
require 'ljglibs.cdefs.pango'
core = require 'ljglibs.core'

C, ffi_new, ffi_gc, ffi_cast = ffi.C, ffi.new, ffi.gc, ffi.cast

attr_gc = (o) ->
  ffi_gc o, (o) ->
    C.pango_attribute_destroy(ffi_cast('PangoAttribute *', o))

PangoAttribute = core.define 'PangoAttribute', {
  constants: {
    prefix: 'PANGO_ATTR_'

    -- PangoAttrType
    'INVALID',
    'LANGUAGE',
    'FAMILY',
    'STYLE',
    'WEIGHT',
    'VARIANT',
    'STRETCH',
    'SIZE',
    'FONT_DESC',
    'FOREGROUND',
    'BACKGROUND',
    'UNDERLINE',
    'STRIKETHROUGH',
    'RISE',
    'SHAPE',
    'SCALE',
    'FALLBACK',
    'LETTER_SPACING',
    'UNDERLINE_COLOR',
    'STRIKETHROUGH_COLOR',
    'ABSOLUTE_SIZE',
    'GRAVITY',
    'GRAVITY_HINT'
  }

  -- We define struct fields as properties again here:
  -- this is make dispatch through sub classes work correctly
  properties: {
    start_index: {
      get: => @start_index
      set: (idx) => @start_index = idx
    }

    end_index: {
      get: => @end_index
      set: (idx) => @end_index = idx
    }
  }

  copy: =>
    attr_gc C.pango_attribute_copy @
}

for atype in *{ 'Color', 'String', 'Int' }
  core.define "PangoAttr#{atype} < PangoAttribute", {}

new_attr = (attr, start_index, end_index) ->
  with attr_gc attr
    .start_index = start_index if start_index
    .end_index = end_index if end_index

with PangoAttribute
  .Foreground = (r, g, b, start_index, end_index) ->
    new_attr C.pango_attr_foreground_new(r, g, b), start_index, end_index

  .Background = (r, g, b, start_index, end_index) ->
    new_attr C.pango_attr_background_new(r, g, b), start_index, end_index

  .Family = (family, start_index, end_index) ->
    new_attr C.pango_attr_family_new(family), start_index, end_index

  .Style = (style, start_index, end_index) ->
    new_attr C.pango_attr_style_new(style), start_index, end_index

  .Variant = (variant, start_index, end_index) ->
    new_attr C.pango_attr_variant_new(variant), start_index, end_index

  .Stretch = (stretch, start_index, end_index) ->
    new_attr C.pango_attr_stretch_new(stretch), start_index, end_index

  .Weight = (weight, start_index, end_index) ->
    new_attr C.pango_attr_weight_new(weight), start_index, end_index

  .Size = (size, start_index, end_index) ->
    new_attr C.pango_attr_size_new(size), start_index, end_index

  .AbsoluteSize = (size, start_index, end_index) ->
    new_attr C.pango_attr_size_new_absolute(size), start_index, end_index

  .Strikethrough = (active, start_index, end_index) ->
    new_attr C.pango_attr_strikethrough_new(active), start_index, end_index

  .StrikethroughColor = (r, g, b, start_index, end_index) ->
    new_attr C.pango_attr_strikethrough_color_new(r, g, b), start_index, end_index

  .Underline = (underline, start_index, end_index) ->
    new_attr C.pango_attr_underline_new(underline), start_index, end_index

  .UnderlineColor = (r, g, b, start_index, end_index) ->
    new_attr C.pango_attr_underline_color_new(r, g, b), start_index, end_index

  .LetterSpacing = (spacing, start_index, end_index) ->
    new_attr C.pango_attr_letter_spacing_new(spacing), start_index, end_index

PangoAttribute
