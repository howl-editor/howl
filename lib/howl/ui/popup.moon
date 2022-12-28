-- Copyright 2012-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
Popover = Gtk.Popover
gobject_signal = require 'ljglibs.gobject.signal'
{:PropertyObject} = howl.util.moon
{:ContentBox} = howl.ui

class Popup extends PropertyObject
  comfort_zone: 10

  new: (@child, properties = {}) =>
    error('Missing argument #1: child', 3) if not child
    @box = ContentBox 'popup', child, {
      header: properties.header,
      footer: properties.footer
    }

    props = {
      autohide: false
      has_arrow: false
      width_request: properties.width or 150
      height_request: properties.height or 150
      child: @box\to_gobject!
    }
    @popover = Popover props
    @popover.child = @box\to_gobject!
    @popover\on_show ->
      print 'on popup show!'
      moon.p @popover.allocation

    @popover\on_realize ->
      print 'on popup realize!'
      moon.p @popover.allocation
     --   print "w: #{@window.allocated_width}, h: #{@window.allocated_height}"
    @popover\on_hide ->
      print 'on popup hide!'

    @showing = false
    super!

  show: (widget, options = position: 'center') =>
    error('Missing argument #1: widget', 2) if not widget
    print "show start"
    status, err = pcall ->
      @popover\set_parent widget
      -- @popover\realize!

      -- @toplevel = widget\get_ancestor(wType)
      -- print "toplevel: #{@toplevel}"
      -- @window.transient_for = @toplevel
      -- @window.modal = true
      -- @window.destroy_with_parent = true
      print "x"
      -- @window\realize!
      @widget = widget
      @showing = true

      -- print "y"
      -- moon.p options
      if options.x
      --   -- @window.window_position = Gtk.WIN_POS_NONE
        status, ret = pcall @move_to, @, options.x, options.y
        print "status: #{status}: #{ret}"
      -- else
      --   status, ret = pcall @center, @
      --   print "status: #{status}: #{ret}"

      print "doing show!"
      -- @window.visible = true
      -- @window\show!
      @popover\popup!
      print "show!"

    unless status
      moon.p err

  close: =>
    print "popup close!"
    -- @window\hide!
    @popover\popdown!
    @showing = false
    @widget = nil

  destroy: =>
    @close!
    -- @popover\unref!
    print "popup destroy!"
    -- @window\destroy!

  move_to: (x, y) =>
    error('Attempt to move a closed popup', 2) if not @showing

    -- alloc = @toplevel.allocation
    -- moon.p alloc
    -- w_x, w_y = alloc.x, alloc.y
    -- -- w_x, w_y = @toplevel\get_position!
    -- t_x, t_y = @widget\translate_coordinates(@toplevel, x, y)
    -- x = w_x + t_x
    -- y = w_y + t_y

    -- @x, @y = x, y
    -- -- @window\move x, y
    -- @resize @window.allocated_width, @window.allocated_height
    @popover.pointing_to = {:x, :y, width: 1, height: 1}

  resize: (width, height) =>
    if not @showing
      @window.default_width = width
      @window.default_height = height
      return


    -- GTK4
    -- screen = @widget.screen

    -- if @x + width > (screen.width - @comfort_zone)
    --   width = screen.width - @x - @comfort_zone

    -- if @y + height > (screen.height - @comfort_zone)
    --   height = screen.height - @y - @comfort_zone

    @width, @height = width, height
    @window\set_size_request width, height
    @window\resize width, height

  center: =>
    error('Attempt to center a closed popup', 2) if not @showing
    height = @height
    width = @width

    -- now, if we were to center ourselves on the widgets toplevel,
    -- with our current width and height..

    -- screen = @widget.screen
    w_x, w_y = @toplevel\get_position!
    w_width, w_height = @toplevel.allocated_width, @toplevel.allocated_height
    win_h_center = w_x + (w_width / 2)
    win_v_center = w_y + (w_height / 2)
    x = win_h_center - (width / 2)
    y = win_v_center - (height / 2)

    -- GTK4
    -- are we outside of the comfort zone horizontally?
    -- if x < @comfort_zone or x + width > (screen.width - @comfort_zone)
    --   -- pull in the stomach
    --   min_outside_h = math.min(w_x, screen.width - (w_x + w_width))
    --   width = (w_width + min_outside_h) - @comfort_zone
    --   x = win_h_center - (width / 2)

    -- -- are we outside of the comfort zone vertically?
    -- if y < @comfort_zone or y + height > (screen.height - @comfort_zone)
    --   -- hunch down
    --   min_outside_v = math.min(w_y, screen.height - (w_y + w_height))
    --   height = (w_height + min_outside_v) - @comfort_zone
    --   y = win_v_center - (height / 2)

    -- now it's all good
    @resize width, height
    @window\move x, y

  _on_destroy: =>
    print "popup on destroy"
    -- disconnect signal handlers
    for h in *@_handlers
      gobject_signal.disconnect h

return Popup
