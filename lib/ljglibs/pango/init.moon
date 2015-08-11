-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

core = require 'ljglibs.core'
require 'ljglibs.cdefs.pango'

core.auto_loading 'pango', {
  constants: {
    prefix: 'PANGO_'
    'ALIGN_LEFT',
    'ALIGN_CENTER',
    'ALIGN_RIGHT',

    -- PangoStyle
    'STYLE_NORMAL',
    'STYLE_OBLIQUE',
    'STYLE_ITALIC'

    -- PangoVariant
    'VARIANT_NORMAL',
    'VARIANT_SMALL_CAPS',

    -- PangoWeight
    'WEIGHT_THIN',
    'WEIGHT_ULTRALIGHT',
    'WEIGHT_LIGHT',
    'WEIGHT_BOOK',
    'WEIGHT_NORMAL',
    'WEIGHT_MEDIUM',
    'WEIGHT_SEMIBOLD',
    'WEIGHT_BOLD',
    'WEIGHT_ULTRABOLD',
    'WEIGHT_HEAVY',
    'WEIGHT_ULTRAHEAVY',

    -- PangoStretch
    'STRETCH_ULTRA_CONDENSED',
    'STRETCH_EXTRA_CONDENSED',
    'STRETCH_CONDENSED',
    'STRETCH_SEMI_CONDENSED',
    'STRETCH_NORMAL',
    'STRETCH_SEMI_EXPANDED',
    'STRETCH_EXPANDED',
    'STRETCH_EXTRA_EXPANDED',
    'STRETCH_ULTRA_EXPANDED'

    -- PangoFontMask
    'FONT_MASK_FAMILY',
    'FONT_MASK_STYLE',
    'FONT_MASK_VARIANT',
    'FONT_MASK_WEIGHT',
    'FONT_MASK_STRETCH',
    'FONT_MASK_SIZE',
    'FONT_MASK_GRAVITY',

    -- PangoUnderline
    'UNDERLINE_NONE',
    'UNDERLINE_SINGLE',
    'UNDERLINE_DOUBLE',
    'UNDERLINE_LOW',
    'UNDERLINE_ERROR',

    -- PangoGravity
    'GRAVITY_SOUTH',
    'GRAVITY_EAST',
    'GRAVITY_NORTH',
    'GRAVITY_WEST',
    'GRAVITY_AUTO',

    -- PangoGravityHint
    'GRAVITY_HINT_NATURAL',
    'GRAVITY_HINT_STRONG',
    'GRAVITY_HINT_LINE',

    -- PangoAttributeConstants
    'ATTR_INDEX_FROM_TEXT_BEGINNING',
    'ATTR_INDEX_TO_TEXT_END',

    -- PangoTabAlign
    'TAB_LEFT'

    -- PangoAttrType
    'ATTR_INVALID'
    'ATTR_LANGUAGE'
    'ATTR_FAMILY'
    'ATTR_STYLE'
    'ATTR_WEIGHT'
    'ATTR_VARIANT'
    'ATTR_STRETCH'
    'ATTR_SIZE'
    'ATTR_FONT_DESC'
    'ATTR_FOREGROUND'
    'ATTR_BACKGROUND'
    'ATTR_UNDERLINE'
    'ATTR_STRIKETHROUGH'
    'ATTR_RISE'
    'ATTR_SHAPE'
    'ATTR_SCALE'
    'ATTR_FALLBACK'
    'ATTR_LETTER_SPACING'
    'ATTR_UNDERLINE_COLOR'
    'ATTR_STRIKETHROUGH_COLOR'
    'ATTR_ABSOLUTE_SIZE'
    'ATTR_GRAVITY'
    'ATTR_GRAVITY_HINT'
  },

  SCALE: 1024
}
