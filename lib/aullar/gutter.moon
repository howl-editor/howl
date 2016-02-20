-- Copyright 2014-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:max, :min, :abs} = math
{:define_class} = require 'aullar.util'
Pango = require 'ljglibs.pango'
{:RGBA} = require 'ljglibs.gdk'
Background = require 'ljglibs.aux.background'
Layout = Pango.Layout
pango_cairo = Pango.cairo

get_bg_conf = (styling = {}) ->
  bg_conf = {}
  if styling.background
    for k, v in pairs styling.background
      bg_conf[k] = v

  for k, v in pairs styling
    bg_conf[k] = v if k\match '^border'

  bg_conf

define_class {
  new: (@view, styling = {}) =>
    @number_chars = 0
    @width = 0
    @background = Background 'gutter', 0, 0
    @reconfigure styling

  reconfigure: (styling) =>
    @background\reconfigure get_bg_conf(styling)
    @_foreground = RGBA(styling.color or '#000000')
    @_foreground_alpha = styling.alpha or 1

  sync_dimensions: (buffer, opts = {}) =>
    lines_text = tostring(buffer.nr_lines)
    num_chars = #lines_text
    return true if not opts.force and @number_chars == num_chars
    {:width} = @view\text_dimensions(lines_text)
    @_text_width = width + 10
    @width = @_text_width + @background.padding_left + @background.padding_right
    @number_chars = num_chars
    @background\resize @width, @view.height
    false

  start_draw: (@cairo_context, pango_context, @clip) =>
    @layout = nil
    return if @clip.x1 >= @width
    @_draw_background!
    @layout = Layout pango_context
    @layout.width = (@_text_width - 5) * Pango.SCALE
    @layout.alignment = Pango.ALIGN_RIGHT

  draw_for_line: (line_nr, x, y, display_line) =>
    return unless @layout

    cr = @cairo_context
    color = @_foreground
    cr\save!
    cr\set_source_rgba color.red, color.green, color.blue, @_foreground_alpha
    @layout.text = tostring line_nr
    _, text_height = @layout\get_pixel_size!
    line_height = display_line.height

    if display_line.is_wrapped
      layout_line = display_line.layout\get_line_readonly 0
      _, log_rect = layout_line\get_pixel_extents!
      line_height = log_rect.height

    cr\move_to x + @background.padding_left, y + (line_height - text_height) / 2
    pango_cairo.show_layout cr, @layout
    cr\restore!

  end_draw: =>
    @cairo_context, @clip, @layout = nil, nil, nil

  _draw_background: =>
    @cairo_context\save!
    @background\draw @cairo_context
    @cairo_context\restore!
}
