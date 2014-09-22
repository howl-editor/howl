-- Copyright 2014 Nils Nordman <nino at nordman.org>
-- License: MIT (see LICENSE)

{:RGBA} = require 'ljglibs.gdk'
Cairo = require 'ljglibs.cairo.cairo'
{:define_class} = require 'aullar.util'
{:max} = math
copy = moon.copy

parse_color = (color) ->
  return color and RGBA(color)

set_source_from_color = (cr, name, opts) ->
  color = opts[name]
  alpha = opts["#{name}_alpha"]
  if color
    if alpha
      cr\set_source_rgba color.red, color.green, color.blue, alpha
    else
      cr\set_source_rgb color.red, color.green, color.blue

draw_ops = {
  rectangle: (x, y, width, height, cr, opts) ->
    set_source_from_color cr, 'background', opts
    cr\rectangle x, y, width, height
    cr\fill!

    if opts.foreground
      set_source_from_color cr, 'foreground', opts
      cr.line_width = opts.line_width or 0.5
      cr\rectangle x, y + 0.5, width, height - 1
      cr\stroke!

  sandwich: (x, y, width, height, cr, opts) ->
    set_source_from_color cr, 'foreground', opts
    cr.line_width = opts.line_width or 0.5

    cr\move_to x, y + 0.5
    cr\rel_line_to width, 0
    cr\stroke!

    cr\move_to x, y + height - 0.5
    cr\rel_line_to width, 0
    cr\stroke!

}

define_class {
  RECTANGLE: 'rectangle'
  SANDWICH: 'sandwich'

  new: (flair_type, opts) =>
    @_draw = draw_ops[flair_type]
    raise "Invalid flair type '#{flair_type}'", 2 unless @_draw
    @opts = copy opts
    @opts.background = parse_color opts.background
    @opts.foreground = parse_color opts.foreground

  draw: (display_line, start_offset, end_offset, x, y, cr) =>
    {:layout, :view} = display_line
    rect = layout\index_to_pos start_offset - 1
    start_x = x + max((rect.x / 1024) - 1, 0) - view.base_x
    start_x = max(start_x, view.edit_area_x)
    rect = layout\index_to_pos end_offset - 1

    get_defined_width = (x, opts, cr) ->
      return opts.width if not opts.width or type(opts.width) == 'number'
      if opts.width == 'full'
        cr.clip_extents.x2 - x

    width = get_defined_width(start_x, @opts, cr)
    width or= (x + rect.x / 1024) - start_x - view.base_x
    width = @opts.min_width if width == 0 and @opts.min_width
    return if width <= 0

    cr\save!
    self._draw start_x, y, width, display_line.height, cr, @opts
    cr\restore!
}
