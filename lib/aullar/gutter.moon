-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Pango = require 'ljglibs.pango'
{:RGBA} = require 'ljglibs.gdk'
Layout = Pango.Layout
pango_cairo = Pango.cairo

define_class {
  new: (@view) =>
    @width = 50

  start_draw: (@cairo_context, pango_context, @clip, styling) =>
    @layout = nil
    return if @clip.x1 >= @width
    @_draw_background styling
    @layout = Layout pango_context
    @layout.width = (@width - 5) * Pango.SCALE
    @layout.alignment = Pango.ALIGN_RIGHT
    @_foreground = RGBA(styling.foreground or '#000000')
    @_foreground_alpha = styling.foreground_alpha or 1

  draw_for_line: (line_nr, x, y, display_line, styling) =>
    return unless @layout

    cr = @cairo_context
    color = @_foreground
    cr\save!
    cr\set_source_rgba color.red, color.green, color.blue, @_foreground_alpha
    @layout.text = tostring line_nr
    _, text_height = @layout\get_pixel_size!
    cr\move_to x, y + (display_line.height - text_height) / 2
    pango_cairo.show_layout cr, @layout
    cr\restore!

  end_draw: =>
    @cairo_context, @clip, @layout = nil, nil, nil

  _draw_background: (styling) =>
    with @cairo_context
      \save!
      color = RGBA(styling.background or '#8294ab')
      alpha = styling.background_alpha or 1
      \set_source_rgba color.red, color.green, color.blue, alpha
      \rectangle @clip.x1, @clip.y1, min(@clip.x2 - @clip.x1, @width), @clip.y2 - @clip.y1
      \fill!
      \restore!
}
