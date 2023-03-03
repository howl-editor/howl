-- Copyright 2012-2023 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
Popover = Gtk.Popover
gobject_signal = require 'ljglibs.gobject.signal'
{:PropertyObject} = howl.util.moon
{:floor} = math

class Popup extends PropertyObject
  comfort_zone: 10

  new: (@child, props = {}) =>
    error('Missing argument #1: child', 3) if not child
    props = {k, v for k, v in pairs props}
    props.autohide = false
    props.has_arrow = false
    props.child = @child
    props.width_request = props.width or 150
    props.height_request = props.height or 150
    @popover = Popover props

    -- @popover.child = @box\to_gobject!
    -- @popover\on_show ->
    --   print 'on popup show!'
    --   moon.p @popover.allocation
    --   print "allocated_height: #{@popover.allocated_height}"
    --   print "popup on_show, width request: #{@popover.width_request}"

    -- @popover\on_realize ->
    --   print 'on popup realize!'
    --   moon.p @popover.allocation
    --  --   print "w: #{@window.allocated_width}, h: #{@window.allocated_height}"
    -- @popover\on_hide ->
    --   print 'on popup hide!'

    @showing = false
    super!

  show: (widget, options = {position: 'center'}) =>
    error('Missing argument #1: widget', 2) if not widget

    status, err = pcall ->
      if @popover.parent != widget
        @popover\set_parent widget
        print "reset parent"

      -- @popover\present!
      -- print 'present'

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
        @move_to options.x, options.y

      io.stderr\write "doing show!\n"
      -- @window.visible = true
      -- @window\show!
      @popover\popup!
      print "popup show!"

    unless status
      moon.p err

  close: =>
    print "popup close!"
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
    @popover.position = Gtk.POS_BOTTOM
    @pointing_to = {:x, :y, width: 1, height: 1}
    -- @popover.pointing_to = {:x, :y, width: 1, height: 1}
    @popover.pointing_to = @pointing_to
    print "set pointing_to"
    moon.p @popover.pointing_to
    print "move_to: width_request: #{@popover.width_request}"
    -- print "allocated_width: #{@popover.allocated_width}"
    -- print "set set_offset width to #{floor(@popover.width_request / 2)}"
    @_set_offset @popover.width_request

  _set_offset: (width, height) =>
    x_off = floor width / 2
    actual = '?'
    -- if @pointing_to
    --   actual = @pointing_to.x - x_off
    print "set x_offset: #{x_off}, actual: #{actual}"

    @popover\set_offset x_off, 0

  resize: (width, height) =>
    if not @showing
      @popover.width_request = width
      @popover.height_request = height
      return


    -- GTK4
    -- screen = @widget.screen

    -- if @x + width > (screen.width - @comfort_zone)
    --   width = screen.width - @x - @comfort_zone

    -- if @y + height > (screen.height - @comfort_zone)
    --   height = screen.height - @y - @comfort_zone

    -- if @showing
      -- @popover\popdown!
    width, height = floor(width), floor(height)
    @width, @height = width, height
    -- print "set set_offset with to #{floor(width / 2)}"
    -- @popover\set_offset floor(width / 2), 0
    @_set_offset width
    print "popup resize: set size request to #{width} x #{height}"
    @popover\set_size_request width, height
    -- @child\set_size_request width, height
    -- if @pointing_to
    --   print "resize: set pointing_to"
    --   @popover.pointing_to = @pointing_to
    -- if @showing
      -- @popover\popup!
    -- @window\resize width, height

  center: =>
    error('Attempt to center a closed popup', 2) if not @showing
    height = @height
    width = @width

    error "popup center NYI"
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
