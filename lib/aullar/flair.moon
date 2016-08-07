-- Copyright 2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

{:RGBA} = require 'ljglibs.gdk'
require 'ljglibs.cairo.context'
{:SCALE, :Layout, :AttrList, :Attribute, :Color, :cairo} = require 'ljglibs.pango'

{:define_class} = require 'aullar.util'
styles = require 'aullar.styles'
Styling = require 'aullar.styling'
{:min, :max, :floor, :pi} = math
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
    else
      cr\set_source_rgba 0, 0, 0, 0, 0

set_line_type_from_flair = (cr, flair) ->
  cr.line_width = flair._line_width
  switch flair.line_type
    when 'dotted'
      cr.dash = {0.5, 1}
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

  rounded_rectangle: (flair, x, y, width, height, cr) ->
    radius = flair.corner_radius or 3

    if width < radius * 3 or height < radius * 3
      radius = min(width, height) / 3

    quadrant = pi / 2
    right, bottom, left, top = 0, quadrant - 0.5, quadrant * 2, (quadrant * 3) + 0.5
    cr\move_to x, y + radius
    cr\arc x + radius, y + radius, radius, left, top
    cr\arc x + width - radius, y + radius, radius, top, right
    cr\arc x + width - radius, y + height - radius, radius, right, bottom
    cr\arc x + radius, y + height - radius, radius, bottom, left
    cr\close_path!

    set_source_from_color cr, 'background', flair
    cr\fill_preserve!
    set_source_from_color cr, 'foreground', flair
    set_line_type_from_flair cr, flair
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

  wavy_underline: (flair, x, y, width, height, cr) ->
    wave_height = flair.wave_height or 2
    line_run = (flair.wave_width or 8) / 2

    runs = math.floor (width / line_run)
    cr\move_to x, y + height - 0.5

    set_source_from_color cr, 'foreground', flair
    set_line_type_from_flair cr, flair

    direction = -1
    for i = 1, runs
      cr\rel_line_to line_run, direction * wave_height
      direction *= -1

    partial_run = width - (runs * line_run)
    if partial_run > 0
      cr\rel_line_to partial_run, (direction * wave_height * partial_run / line_run)

    cr\stroke!

  pipe: (flair, x, y, width, height, cr) ->
    if flair.foreground
      set_source_from_color cr, 'foreground', flair
      set_line_type_from_flair cr, flair
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


  -- need to set the correct attributes when we have a different text color
  -- or need to determine the height of the text object correctly
  if flair.text_color or flair.height == 'text'
    styling = Styling.sub display_line.styling, start_offset, end_offset
    exclude = flair.text_color and {color: true} or {}
    attributes = styles.get_attributes styling, text_size, :exclude

    if flair.text_color
      color = Color flair.text_color
      attributes\insert_before Attribute.Foreground(color.red, color.green, color.blue)
    layout.attributes = attributes

  width, height = layout\get_pixel_size!
  :layout, :width, :height

need_text_object = (flair) ->
  flair.text_color or flair.height == 'text'

{
  RECTANGLE: 'rectangle'
  ROUNDED_RECTANGLE: 'rounded_rectangle'
  SANDWICH: 'sandwich'
  UNDERLINE: 'underline'
  WAVY_UNDERLINE: 'wavy_underline'
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
    if need_text_object(flair) and not display_line.is_wrapped
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

    {:layout, :view, :is_wrapped, :lines} = display_line
    clip = cr.clip_extents
    base_x = view.base_x
    width_of_space = display_line.width_of_space
    line_y_offset = 0

    for nr = 1, #lines
      line = lines[nr]

      off_line = start_offset > line.line_end or end_offset < line.line_start
      if off_line or end_offset == line.line_start and (start_offset != end_offset)
        line_y_offset += line.height
        continue -- flair not within this layout line

      f_start_offset = max start_offset, line.line_start
      f_end_offset = min line.line_end, end_offset
      start_rect = layout\index_to_pos f_start_offset - 1
      flair_y = y + start_rect.y / SCALE
      text_start_x = x + max((start_rect.x / SCALE), 0) - base_x
      start_x = max(text_start_x, view.edit_area_x)

      width = get_defined_width(start_x, flair, cr, clip)
      unless width
        end_rect = layout\index_to_pos f_end_offset - 1
        end_x = end_rect.x / SCALE
        width = x + end_x - start_x - base_x

      if flair.min_width
        flair_min_width = flair.min_width
        flair_min_width = width_of_space if flair_min_width == 'letter'
        width = max(flair_min_width - base_x, width)

      -- why draw a zero-width flair?
      return if width <= 0

      text_object = flair.text_object

      if not text_object and need_text_object(flair)
        ft_end_offset = min line.line_end + 1, end_offset
        text_object = get_text_object display_line, f_start_offset, ft_end_offset, flair

      -- height calculations
      height = type(flair.height) == 'number' and flair.height or line.height

      if (flair.height == 'text' or flair.text_color) and height > text_object.height
        flair_y += display_line.y_offset
        height = text_object.height
        l_baseline = line.baseline - line_y_offset
        bl_diff = floor (l_baseline - (text_object.layout.baseline / SCALE))

        if bl_diff > 0
          flair_y += bl_diff


      cr\save!
      flair.draw flair, start_x, flair_y, width, height, cr
      cr\restore!

      if flair.text_color
        cr\save!
        if base_x > 0
          cr\rectangle x, flair_y, clip.x2 - x, clip.y2
          cr\clip!

        cr\move_to text_start_x, flair_y
        cairo.show_layout cr, text_object.layout
        cr\restore!

      line_y_offset += line.height

}
