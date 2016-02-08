-- Copyright 2015-2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gdk = require 'ljglibs.gdk'
cairo = require 'ljglibs.cairo'

{:RGBA, :Pixbuf} = Gdk
{:min, :max, :pi, :ceil, :floor} = math

-- surface cache
surfaces = {}

class Background
  new: (@name, @width, @height, opts = {})=>
    @reconfigure opts

  reconfigure: (opts = {})=>
    @padding, @border_radius = 0, 0
    if opts.border
      @padding = opts.border.width or 1
      if opts.border.radius and opts.border.radius > 0
        @border_radius = opts.border.radius
        @padding -= @padding / 4
        @padding = ceil @padding

    @padding_top = @padding
    @padding_right = @padding
    @padding_bottom = @padding
    @padding_left = @padding

    if opts.border_top
      @padding_top = max opts.border_top.width or 1, @padding

    if opts.border_right
      @padding_right = max opts.border_right.width or 1, @padding

    if opts.border_bottom
      @padding_bottom = max opts.border_bottom.width or 1, @padding

    if opts.border_left
      @padding_left = max opts.border_left.width or 1, @padding

    @has_padding = @padding_left + @padding_top + @padding_right + @padding_bottom > 0
    @opts = opts
    @_surface = nil
    surfaces[@name] = nil

  resize: (width, height) =>
    return if (not width or width == @width) and (not height or height == @height)
    @width = width if width
    @height = height if height

    -- keep one reference to the previous surface to save it from GC
    if @_surface
      @_previous_surface = @_surface

    @_surface = nil

  draw: (cr, opts = {}) =>
    needs_path = true
    clip = opts.clip or cr.clip_extents

    unless @_surface
      if @_create_surface(cr.target)
        needs_path = false -- clipped by _create_surface

    draw_height = min @height, clip.y2 - clip.y1

    with cr
      \save!
      \set_source_surface @_surface, 0, 0
      \rectangle clip.x1 - 1, clip.y1 - 1, clip.x2 - clip.x1 + 2, draw_height + 2
      \fill_preserve!
      \restore!

    if opts.should_clip and needs_path and @_needs_clip(clip)
      @_setup_path cr, @padding_top, @padding_right + @padding_left, @padding_bottom + @padding_top, @padding_left
      cr\clip!

  _needs_clip: (clip) =>
    if @has_padding
      return true if clip.x1 < @padding_left or clip.x2 >= @width - @padding_right
      return true if clip.y1 < @padding_top or clip.y2 >= @height - @padding_bottom

    false

  _create_surface: (target) =>
    cache = surfaces[@name]
    unless cache
      cache = setmetatable {}, __mode: 'v'
      surfaces[@name] = cache

    cache_key = "#{@width}x#{@height}"
    @_surface = cache[cache_key]
    if @_surface
      return false -- re-use existing surface

    content = cairo.CONTENT_COLOR_ALPHA
    surface = cairo.Surface.create_similar target, content, @width, @height
    cr = cairo.Context surface

    @_draw_border cr

    @_setup_path cr, @padding_top, @padding_right + @padding_left, @padding_bottom + @padding_top, @padding_left
    @_draw_background cr
    @_surface = surface

    if @opts.prepare
      cr\save!
      cr\translate @padding_left, @padding_top
      cr\clip_preserve!
      @opts.prepare @, cr
      cr\restore!

    cache[cache_key] = surface
    true

  _draw_border: (cr) =>
    {:border, :border_top, :border_right, :border_bottom, :border_left} = @opts

    if border
      if border.color -- solid color
        @_setup_path cr, @padding_top / 2, (@padding_right + @padding_left) / 2, (@padding_bottom + @padding_top) / 2, @padding_left / 2
        cr.line_width = border.width or 1
        color = RGBA(border.color)
        cr\set_source_rgba color.red, color.green, color.blue, border.alpha or 1
        cr\stroke!

    draw_line = (cr, x, y, rel_x, rel_y, def) ->
      cr\save!
      cr\new_path!
      width = def.width or 1
      cr.line_width = width
      color = RGBA(def.color or '#000000')
      cr\set_source_rgba color.red, color.green, color.blue, def.alpha or 1

      cr\move_to x, y
      cr\rel_line_to rel_x, rel_y
      cr\stroke!
      cr\restore!

    if border_top
      width = border_top.width or 1
      draw_line cr, 0, width / 2, @width, 0, border_top

    if border_bottom
      width = border_bottom.width or 1

      draw_line cr, 0, (@height - width) + (width / 2), @width, 0, border_bottom

    if border_right
      width = border_right.width or 1
      draw_line cr, (@width - width) + (width / 2), 0, 0, @height, border_right

    if border_left
      width = border_left.width or 1
      draw_line cr, (width / 2), 0, 0, @height, border_left

  _draw_background: (cr) =>
    {:color, :image, :gradient} = @opts

    if color
      @_fill_with_color cr, color, @opts.alpha
    elseif image
      @_fill_with_image cr, image

    if gradient
      @_fill_with_gradient cr, gradient

  _fill_with_color: (cr, color, alpha = 1) =>
    c = RGBA(color)
    cr\set_source_rgba c.red, c.green, c.blue, alpha
    cr\fill_preserve!

  _fill_with_image: (cr, image) =>
    unless image.path
      error "Missing attribute 'path' from background image configuration", 3

    if image.repeat == 'stretch'
      pb = Pixbuf.new_from_file_at_scale tostring(image.path), @width, @height, false
      Gdk.cairo.set_source_pixbuf cr, pb, 0, 0
      cr\fill_preserve!
    else
      pb = Pixbuf.new_from_file tostring(image.path)
      Gdk.cairo.set_source_pixbuf cr, pb, 0, 0
      cr.source.extend = cairo.EXTEND_REPEAT
      cr\fill_preserve!

  _fill_with_gradient: (cr, gradient) =>
    for attr in *{'stops', 'type', 'direction'}
      unless gradient[attr]
        error "Missing attribute '#{attr}' from background gradient configuration", 3

    unless gradient.type == 'linear'
      error "Unsupported gradient type '#{gradient.type}' (only 'linear' supported)"

    end_x, end_y = switch gradient.direction
      when 'horizontal'
        @width, 0
      when 'vertical'
        0, @height
      when 'diagonal'
        @width, @height

    alpha = gradient.alpha

    pattern = cairo.pattern.create_linear 0, 0, end_x, end_y
    for i = 1, #gradient.stops
      spec = gradient.stops[i]

      offset = (i - 1) / (#gradient.stops - 1)
      color = spec

      if type(spec) == 'table'
        offset, color = spec[1], spec[2]

      c = RGBA(color)
      pattern\add_color_stop_rgba offset, c.red, c.green, c.blue, alpha or c.alpha

    cr.source = pattern
    cr\fill_preserve!

  _setup_path: (cr, edge_top, edge_right, edge_bottom, edge_left) =>
    border = @opts.border
    cr\new_path!

    if not border or @border_radius == 0
      cr\rectangle edge_left, edge_top, @width - edge_right, @height - edge_bottom
      return

    radius = @border_radius

    if @width < radius * 3 or @height < radius * 3
      radius = min(@width, @height) / 3

    quadrant = pi / 2
    right, bottom, left, top = 0, quadrant, quadrant * 2, (quadrant * 3)
    cr\arc radius + edge_top, radius + edge_top, radius, left, top
    cr\arc @width - radius - edge_top, radius + edge_top, radius, top, right
    cr\arc @width - radius - edge_top, @height - radius - edge_top, radius, right, bottom
    cr\arc radius + edge_top, @height - radius - edge_top, radius, bottom, left
    cr\close_path!
