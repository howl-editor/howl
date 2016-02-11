-- Copyright 2015-2016 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gdk = require 'ljglibs.gdk'
Gtk = require 'ljglibs.gtk'
cairo = require 'ljglibs.cairo'
gobject_signal = require 'ljglibs.gobject.signal'
ffi = require 'ffi'

{:signal} = howl
{:Background, :theme} = howl.ui
{:PropertyObject} = howl.aux.moon
{:RGBA, :Pixbuf} = Gdk
append = table.insert
ffi_cast = ffi.cast
{:min, :max} = math

allocations_differ = (a1, a2) ->
  a1.x != a2.x or a1.y != a2.y or a1.width != a2.width or a1.height != a2.height

get_bg_conf = (theme_conf = {}, additional) ->
  bg_conf = {}
  if theme_conf.background
    for k, v in pairs theme_conf.background
      bg_conf[k] = v

  for k, v in pairs theme_conf
    bg_conf[k] = v if k\match '^border'

  if additional
    for k, v in pairs additional
      bg_conf[k] = v

  bg_conf

class ContentBox extends PropertyObject

  new: (@name, @content_widget, opts = {})=>
    @opts = opts

    @_handlers = {}
    @main = background: Background "#{name}_bg", 0, 0

    if opts.header
      @header = @_create_bar opts.header, opts.header_background, @main, "header"

    if opts.footer
      @footer = @_create_bar opts.footer, opts.footer_background, @main, "footer"

    main_widget = Gtk.Box Gtk.ORIENTATION_VERTICAL

    if @header
      main_widget\pack_start @header.widget, false, false, 0

    main_widget\pack_start content_widget, true, true, 0

    if @footer
      main_widget\pack_start @footer.widget, false, false, 0

    @main.widget = main_widget
    @e_box = Gtk.EventBox {
      hexpand: true,
      main_widget
    }
    @e_box.app_paintable = true

    append @_handlers, @e_box\on_size_allocate self\_on_size_allocate
    append @_handlers, @e_box\on_destroy self\_on_destroy
    append @_handlers, @e_box\on_draw self\_draw

    @_theme_changed = self\_on_theme_changed
    signal.connect 'theme-changed', @_theme_changed
    @_on_theme_changed theme: theme.current

  to_gobject: => @e_box

  _prepare_background: (bg, cr) =>
    if @header and @header.background and @header.widget.visible
      cr\save!
      @header.background\draw cr
      cr\restore!

    if @footer and @footer.background
      cr\save!
      cr\translate 0, bg.height - @footer.background.height - bg.padding_bottom - bg.padding_top
      @footer.background\draw cr
      cr\restore!

  _draw: (_, cr) =>
    cr\save!
    clip = cr.clip_extents
    bg = @main.background
    bg\draw cr, should_clip: true, :clip
    cr\translate bg.padding_left, bg.padding_top
    gobject_signal.emit_by_name @main.widget, 'draw', cr
    cr\restore!
    true

  _on_theme_changed: (opts) =>
    def = opts.theme[@name] or opts.theme.content_box or {}
    bg_conf = get_bg_conf def, prepare: self\_prepare_background

    main_bg = @main.background
    main_bg\reconfigure bg_conf

    with @main.widget
      .margin_top = main_bg.padding_top
      .margin_right = main_bg.padding_right
      .margin_bottom = main_bg.padding_bottom
      .margin_left = main_bg.padding_left

    corner_padding = main_bg.border_radius

    reconfigure_bar = (bar) ->
      bg = bar.background
      bar_conf = def[bar.name] or {}
      bar_bg_conf = get_bg_conf bar_conf
      bg\reconfigure bar_bg_conf
      bar_padding = bar_conf.padding or 0
      with bar.widget
        .margin_top = bg.padding_top + max(bar_conf.padding_top or 0, bar_padding)
        .margin_right = max(bg.padding_right, corner_padding, main_bg.padding_right) + max(bar_conf.padding_right or 0, bar_padding)
        .margin_bottom = bg.padding_bottom + max(bar_conf.padding_bottom or 0, bar_padding)
        .margin_left = max(bg.padding_left, corner_padding, main_bg.padding_left) + max(bar_conf.padding_left or 0, bar_padding)

    reconfigure_bar @header if @header
    reconfigure_bar @footer if @footer

  _on_destroy: =>
    -- disconnect signal handlers
    for h in *@_handlers
      gobject_signal.disconnect h

    signal.disconnect 'theme-changed', @_theme_changed

  _create_bar: (widget, background_configuration, parent, name) =>
    bg = Background "#{@name}_#{name}", 0, 0
    b_w = Gtk.Box Gtk.ORIENTATION_VERTICAL, { widget }
    bar = :name, widget: b_w, background: bg
    append @_handlers, bar.widget\on_size_allocate self\_on_bar_size_allocate, bar
    bar

  _on_size_allocate: (_, allocation) =>
    allocation = ffi_cast('GdkRectangle *', allocation)
    @_height = allocation.height

    return if @_allocation and not allocations_differ(@_allocation, allocation)

    with allocation
      @_allocation = x: .x, y: .y, width: .width, height: .height

    @main.background\resize allocation.width, allocation.height

    w_adjustment = @main.background.padding_left + @main.background.padding_right

    if @header and @header.background
      @header.background\resize allocation.width - w_adjustment, nil

    if @footer and @footer.background
      @footer.background\resize allocation.width - w_adjustment, nil

  _on_bar_size_allocate: (_, allocation, bar) =>
    allocation = ffi_cast('GdkRectangle *', allocation)
    return if bar.allocation and not allocations_differ(bar.allocation, allocation)

    w = bar.widget
    height_adjust = w.margin_top + w.margin_bottom
    bar.background\resize nil, allocation.height + height_adjust
    with allocation
      bar.allocation = x: .x, y: .y, width: .width, height: .height
