-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:RGBA} = require 'ljglibs.gdk'
Cairo = require 'ljglibs.cairo.cairo'
{:define_class} = require 'aullar.util'
{:max} = math
copy = moon.copy

flairs = {}

parse_color = (color) ->
  return color and RGBA(color)

set_source_from_color = (cr, name, opts) ->
  color = opts["_#{name}"]
  alpha = opts["#{name}_alpha"]
  if color
    if alpha
      cr\set_source_rgba color.red, color.green, color.blue, alpha
    else
      cr\set_source_rgb color.red, color.green, color.blue

draw_ops = {
  rectangle: (x, y, width, height, cr, flair) ->
    cr.line_join = Cairo.LINE_JOIN_ROUND
    cr.line_cap = Cairo.LINE_CAP_ROUND

    if flair.background
      set_source_from_color cr, 'background', flair
      cr\rectangle x, y, width, height
      cr\fill!

    if flair.foreground
      set_source_from_color cr, 'foreground', flair
      cr.line_width = flair.line_width or 0.5
      cr.line_join = Cairo.LINE_JOIN_ROUND
      cr.line_cap = Cairo.LINE_CAP_ROUND
      cr\rectangle x, y + 0.5, width, height - 1
      cr\stroke!

  sandwich: (x, y, width, height, cr, flair) ->
    set_source_from_color cr, 'foreground', flair
    cr.line_width = flair.line_width or 0.5

    cr\move_to x, y + 0.5
    cr\rel_line_to width, 0
    cr\stroke!

    cr\move_to x, y + height - 0.5
    cr\rel_line_to width, 0
    cr\stroke!

  underline: (x, y, width, height, cr, flair) ->
    set_source_from_color cr, 'foreground', flair
    cr.line_width = flair.line_width or 0.5

    cr\move_to x, y + height - 0.5
    cr\rel_line_to width, 0
    cr\stroke!
}

build = (params) ->
  params = copy params
  params._draw = draw_ops[params.type]
  error "Invalid flair type '#{params.type}'", 2 unless params._draw
  params._background = parse_color params.background
  params._foreground = parse_color params.foreground
  params

define = (name, opts) ->
  flair = build opts
  flairs[name] = flair

{
  RECTANGLE: 'rectangle'
  SANDWICH: 'sandwich'
  UNDERLINE: 'underline'

  :build
  :define

  define_default: (name, flair_type, opts) ->
    unless flairs[name]
      define name, flair_type, opts

  get: (name) -> flairs[name]

  clear: (name) ->
    if name
      flairs[name] = nil
    else
      flairs = {}

  draw: (flair, display_line, start_offset, end_offset, x, y, cr) ->
    flair = flairs[flair] if type(flair) == 'string'
    return unless flair
    {:layout, :view} = display_line
    rect = layout\index_to_pos start_offset - 1
    start_x = x + max((rect.x / 1024) - 1, 0) - view.base_x
    start_x = max(start_x, view.edit_area_x)
    rect = layout\index_to_pos end_offset - 1

    get_defined_width = (x, flair, cr) ->
      return flair.width if not flair.width or type(flair.width) == 'number'
      if flair.width == 'full'
        cr.clip_extents.x2 - x

    width = get_defined_width(start_x, flair, cr)
    width or= (x + rect.x / 1024) - start_x - view.base_x
    width = flair.min_width if width == 0 and flair.min_width
    return if width <= 0

    cr\save!
    flair._draw start_x, y, width, display_line.height, cr, flair
    cr\restore!
}
