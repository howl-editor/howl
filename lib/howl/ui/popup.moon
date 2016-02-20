-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
{:RGBA} = require 'ljglibs.gdk'
Window = Gtk.Window
gobject_signal = require 'ljglibs.gobject.signal'
{:PropertyObject} = howl.aux.moon
{:ContentBox, :theme} = howl.ui

append = table.insert

class Popup extends PropertyObject
  comfort_zone: 10

  new: (@child, properties = {}) =>
    error('Missing argument #1: child', 3) if not child

    @_handlers = {}

    @box = ContentBox 'popup', child, {
      header: properties.header,
      footer: properties.footer
    }

    properties.default_height = 150 if not properties.default_height
    properties.default_width = 150 if not properties.default_width
    @window = Window Window.POPUP, properties

    @window.app_paintable = true
    @_set_alpha!

    append @_handlers, @window\on_screen_changed self\_on_screen_changed
    append @_handlers, @window\on_destroy self\_on_destroy
    @window\add @box\to_gobject!
    @showing = false
    super!

  show: (widget, options = position: 'center') =>
    error('Missing argument #1: widget', 2) if not widget
    @window.transient_for = widget.toplevel
    @window.destroy_with_parent = true
    @window\realize!
    @widget = widget
    @showing = true

    if options.x
      @window.window_position = Gtk.WIN_POS_NONE
      @move_to options.x, options.y
    else
      @center!

    @window\show_all!

  close: =>
    @window\hide!
    @showing = false
    @widget = nil

  destroy: =>
    @window\destroy!

  move_to: (x, y) =>
    error('Attempt to move a closed popup', 2) if not @showing
    w_x, w_y = @widget.toplevel.window\get_position!
    t_x, t_y = @widget\translate_coordinates(@widget.toplevel, x, y)
    x = w_x + t_x
    y = w_y + t_y

    @x, @y = x, y
    @window\move x, y
    @resize @window.allocated_width, @window.allocated_height

  resize: (width, height) =>
    if not @showing
      @window.default_width = width
      @window.default_height = height
      return

    screen = @widget.screen

    if @x + width > (screen.width - @comfort_zone)
      width = screen.width - @x - @comfort_zone

    if @y + height > (screen.height - @comfort_zone)
      height = screen.height - @y - @comfort_zone

    @width, @height = width, height
    @window\set_size_request width, height
    @window\resize width, height

  center: =>
    error('Attempt to center a closed popup', 2) if not @showing
    height = @height
    width = @width

    -- now, if we were to center ourselves on the widgets toplevel,
    -- with our current width and height..

    screen = @widget.screen
    toplevel = @widget.toplevel
    w_x, w_y = toplevel.window\get_position!
    w_width, w_height = toplevel.allocated_width, toplevel.allocated_height
    win_h_center = w_x + (w_width / 2)
    win_v_center = w_y + (w_height / 2)
    x = win_h_center - (width / 2)
    y = win_v_center - (height / 2)

    -- are we outside of the comfort zone horizontally?
    if x < @comfort_zone or x + width > (screen.width - @comfort_zone)
      -- pull in the stomach
      min_outside_h = math.min(w_x, screen.width - (w_x + w_width))
      width = (w_width + min_outside_h) - @comfort_zone
      x = win_h_center - (width / 2)

    -- are we outside of the comfort zone vertically?
    if y < @comfort_zone or y + heigth > (screen.height - @comfort_zone)
      -- hunch down
      min_outside_v = math.min(w_y, screen.height - (w_y + w_height))
      height = (w_height + min_outside_v) - @comfort_zone
      y = win_v_center - (height / 2)

    -- now it's all good
    @resize width, height
    @window\move x, y

  _set_alpha: =>
    screen = @window.screen
    if screen.is_composited
      visual = screen.rgba_visual
      @window.visual = visual if visual

  _on_screen_changed: =>
    @_set_alpha!

  _on_destroy: =>
    -- disconnect signal handlers
    for h in *@_handlers
      gobject_signal.disconnect h

return Popup
