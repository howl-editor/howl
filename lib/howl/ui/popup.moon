-- Copyright 2012-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
Popover = Gtk.Popover
gobject_type = require 'ljglibs.gobject.type'
{:PropertyObject} = howl.util.moon
{:floor} = math
ffi = require 'ffi'

class Popup extends PropertyObject
  comfort_zone: 10

  new: (@child, props = {}) =>
    error('Missing argument #1: child', 3) if not child
    props = {k, v for k, v in pairs props}
    props.autohide = false
    props.has_arrow = false
    props.child = @child
    @width = props.width or 150
    @height = props.height or 150
    props.width_request = @width
    props.height_request = @height
    @popover = Popover props
    @showing = false
    super!

  show: (widget, options = {position: 'center'}) =>
    error('Missing argument #1: widget', 2) if not widget

    if @popover.parent != widget
      @popover\set_parent widget

    @widget = widget
    @showing = true

    if options.pointing_to
      @move_to options.pointing_to
    else
      @center!

    @popover\popup!

  close: =>
    @popover\popdown!
    @showing = false
    @widget = nil

  release: =>
    @close!
    @popover\unparent!
    @child = nil
    @popover = nil

  move_to: (pointing_to) =>
    error('Attempt to move a closed popup', 2) if not @showing

    @x, @y = pointing_to.x, pointing_to.y
    pointing_to.width = 1
    @popover.position = Gtk.POS_BOTTOM
    @pointing_to = pointing_to
    @popover.pointing_to = @pointing_to
    @_set_offset @popover.width_request
    @resize @popover.width_request, @popover.height_request

  _set_offset: (width) =>
    x_off = floor width / 2
    @popover\set_offset x_off, 0

  resize: (width, height) =>
    if not @showing
      return

    native = @widget\get_native!
    display = @widget\get_display!
    monitor = display\get_monitor_at_surface native\get_surface!
    geom = monitor\get_geometry!

    if @x + width > (geom.width - @comfort_zone)
      width = geom.width - @x - @comfort_zone

    if @y + height > (geom.height - @comfort_zone)
      height = geom.height - @y - @comfort_zone

    if not @showing
      @popover.width_request = width
      @popover.height_request = height
      return

    width, height = floor(width), floor(height)
    @width, @height = width, height
    @_set_offset width
    @popover\set_size_request width, height

  center: =>
    error('Attempt to center a closed popup', 2) if not @showing
    height = @height
    width = @width
    comfort = @comfort_zone * 2

    win_type = gobject_type.from_name('GtkWindow')
    win = ffi.cast 'GtkWindow *', @widget\get_ancestor(win_type)

    if @popover.parent != win
      @popover\set_parent win

    w_width, w_height = win.allocated_width, win.allocated_height

    -- are we too wide?
    if width + comfort > w_width
      width = w_width - comfort
      print "center: width set to #{width}"

    -- -- are we too tall?
    if height + comfort > w_height
      height = w_height - comfort
      print "center: height set to #{height}, w_height: #{w_height}"

    @popover\set_size_request width, height

    -- we're small enough size wise, let's place us where we should be
    x = (w_width / 2) - (width / 2)
    y = (w_height / 2) - (height / 2)

    @popover.position = Gtk.POS_BOTTOM
    @pointing_to = {:x, :y, width: 1, height: 1}
    @popover.pointing_to = @pointing_to
    @popover\set_offset(width / 2, 0)

return Popup
