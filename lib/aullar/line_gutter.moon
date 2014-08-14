-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Pango = require 'ljglibs.pango'
Layout = Pango.Layout
pango_cairo = Pango.cairo

CLayout = require 'ljglibs.pango.layout'

LineGutter = {
  new: (@view) =>
    @width = 50

  start_draw: (@cairo_context, pango_context, @clip) =>
    return if @clip.x1 >= @width
    @_draw_background!
    @layout = Layout pango_context
    @layout.width = (@width - 5) * 1024
    @layout.alignment = Pango.ALIGN_RIGHT

  draw_for_line: (line_nr, x, y, display_line) =>
    return unless @layout

    cr = @cairo_context
    cr\save!
    cr\move_to x, y
    @layout.text = tostring line_nr
    pango_cairo.show_layout cr, @layout
    cr\restore!

  end_draw: =>
    @cairo_context, @clip, @layout = nil, nil, nil

  _draw_background: =>
    with @cairo_context
      \save!
      \set_source_rgb 0.5, 0.6, 0.4
      \rectangle @clip.x1, @clip.y1, min(@clip.x2 - @clip.x1, @width), @clip.y2 - @clip.y1
      \fill!
      \restore!
}

define_class LineGutter
