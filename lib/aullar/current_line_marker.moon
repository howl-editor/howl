-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

Flair = require 'aullar.flair'
{:max, :min} = math
{:define_class} = require 'aullar.util'
{:Attribute} = require 'ljglibs.pango'

CurrentLineMarker = {
  new: (@view) =>
    @background_flair = Flair Flair.RECTANGLE, {
      background: '#e3e3e3'
      width: 'full'
    }

    @overlay_flair = Flair Flair.SANDWICH, {
      foreground: '#a3a3a3'
    }

  draw_before: (x, y, display_line, cr, clip) =>
    @background_flair\draw display_line, 0, 0, x, y, cr

  draw_after: (x, y, display_line, cr, clip) =>
    bg_ranges = display_line\get_attribute_ranges Attribute.BACKGROUND, 0, math.huge
    return unless #bg_ranges > 0

    for range in *bg_ranges
      @overlay_flair\draw display_line, range.start_index, range.end_index, x, y, cr
}

define_class CurrentLineMarker
