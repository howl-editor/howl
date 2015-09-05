-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:RGBA} = require 'ljglibs.gdk'
Cairo = require 'ljglibs.cairo.cairo'
{:SCALE, :Layout, :AttrList, :Attribute, :Color, :cairo} = require 'ljglibs.pango'

{:define_class} = require 'aullar.util'
styles = require 'aullar.styles'
Styling = require 'aullar.styling'
{:min, :max, :floor} = math
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

set_line_type_from_flair = (cr, flair) ->
  cr.line_width = flair._line_width
  switch flair.line_type
    when 'dotted'
      cr.dash = {1, 1.5}
    when 'dashed'
      cr.dash = {6, 3}

draw_ops = {
  rectangle: (flair, x, y, width, height, cr) ->

    if flair.background
      set_source_from_color cr, 'background', flair
      cr\rectangle x, y, width, height
      cr\fill!

    if flair.foreground
      set_source_from_color cr, 'foreground', flair
      set_line_type_from_flair cr, flair
      line_width = flair._line_width
      cr\rectangle x, y + (line_width / 2), width, height - line_width
      cr\stroke!

  sandwich: (flair, x, y, width, height, cr) ->
    set_source_from_color cr, 'foreground', flair
    set_line_type_from_flair cr, flair

    cr\move_to x, y + 0.5
    cr\rel_line_to width, 0
    cr\stroke!

    cr\move_to x, y + height - 0.5
    cr\rel_line_to width, 0
    cr\stroke!

  underline: (flair, x, y, width, height, cr) ->
    set_source_from_color cr, 'foreground', flair
    set_line_type_from_flair cr, flair

    cr\move_to x, y + height - 0.5
    cr\rel_line_to width, 0
    cr\stroke!

  pipe: (flair, x, y, width, height, cr) ->
    if flair.foreground
      set_source_from_color cr, 'foreground', flair
      set_line_type_from_flair cr, flair
      line_width = flair.line_width or 0.5
      cr\move_to x + 0.5, y
      cr\rel_line_to 0, height
      cr\stroke!
}

build = (params) ->
  flair = copy params
  flair.draw = draw_ops[params.type]
  error "Invalid flair type '#{params.type}'", 2 unless flair.draw
  flair._background = parse_color params.background
  flair._foreground = parse_color params.foreground
  flair._line_width = params.line_width or 0.5
  flair

define = (name, opts) ->
  flair = build opts
  flairs[name] = flair

get_text_object = (display_line, start_offset, end_offset, flair) ->
  layout = Layout display_line.pango_context
  dline_layout = display_line.layout
  text_size = end_offset - start_offset
  t_ptr = dline_layout\get_text!
  layout\set_text t_ptr + start_offset - 1, text_size
  layout.tabs = dline_layout.tabs

  if flair.text_color
    styling = Styling.sub display_line.styling, start_offset, end_offset
    attributes = styles.get_attributes styling, text_size, exclude: { color: true }
    color = Color flair.text_color
    attributes\insert_before Attribute.Foreground(color.red, color.green, color.blue)
    layout.attributes = attributes

  width, height = layout\get_pixel_size!
  :layout, :width, :height

need_text_object = (flair) ->
  flair.text_color or flair.height == 'text'

{
  RECTANGLE: 'rectangle'
  SANDWICH: 'sandwich'
  UNDERLINE: 'underline'
  PIPE: 'pipe'

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

  compile: (flair, start_offset, end_offset, display_line) ->
    flair = flairs[flair] if type(flair) == 'string'
    return nil unless flair
    if need_text_object flair
      flair = moon.copy flair
      flair.text_object = get_text_object display_line, start_offset, end_offset, flair

    flair

  draw: (flair, display_line, start_offset, end_offset, x, y, cr) ->

    get_defined_width = (x, flair, cr, clip) ->
      return flair.width if type(flair.width) == 'number'
      if flair.width == 'full'
        clip.x2 - x

    flair = flairs[flair] if type(flair) == 'string'
    return unless flair

    {:layout, :view} = display_line
    clip = cr.clip_extents
    base_x = view.base_x
    rect = layout\index_to_pos start_offset - 1
    text_start_x = x + max((rect.x / SCALE) - 1, 0) - base_x
    start_x = max(text_start_x, view.edit_area_x)
    rect = layout\index_to_pos end_offset - 1
    width = get_defined_width(start_x, flair, cr, clip)
    width or= x + (rect.x / SCALE) - start_x - base_x

    if flair.min_width
      flair_min_width = flair.min_width

      if flair_min_width == 'letter'
        flair_min_width = display_line.width_of_space

      width = max(flair_min_width - base_x, width)

    return if width <= 0

    text_object = flair.text_object

    if not text_object and need_text_object(flair)
      text_object = get_text_object display_line, start_offset, end_offset, flair

    {:height, :y_offset} = display_line
    adjusted_for_text_height = false

    if flair.height == 'text' and height > text_object.height
      y += y_offset + (display_line.layout.baseline - text_object.layout.baseline) / SCALE
      height = text_object.height
      adjusted_for_text_height = true

    cr\save!
    flair.draw flair, start_x, y, width, height, cr
    cr\restore!

    if flair.text_color
      if not adjusted_for_text_height and height > text_object.height
        y += y_offset + (display_line.layout.baseline - text_object.layout.baseline) / SCALE

      cr\save!
      if base_x > 0
        cr\rectangle x, y, clip.x2 - x, clip.y2
        cr\clip!

      cr\move_to text_start_x, y
      cairo.show_layout cr, text_object.layout
      cr\restore!

}
