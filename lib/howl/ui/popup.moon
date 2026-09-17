-- Copyright 2012-2024 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
Popover = Gtk.Popover
{:PropertyObject} = howl.util.moon
{:floor} = math

class Popup extends PropertyObject
  comfort_zone: 10

  new: (@child, opts = {}) =>
    error('Missing argument #1: child', 3) if not child
    props = {
      autohide: false,
      has_arrow: false
    }
    for k, v in pairs opts
      props[k] = v
    props.child = @child
    @width = props.width
    @height = props.height
    props.width_request = @width
    props.height_request = @height
    @popover = Popover props
    @showing = false
    super!

  show: (widget, @show_options = {position: 'center'}) =>
    error('Missing argument #1: widget', 2) if not widget
    if not (@width and @height)
      error("Can not show a popup without a size")

    if @popover.parent != widget
      if @popover.parent != nil
        @popover\unparent!

      @popover\set_parent widget

    @widget = widget
    @showing = true

    if show_options.pointing_to
      @move_to show_options.pointing_to
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

  resize: (width, height) =>
    if not @showing
      @width = width
      @height = height
      @popover.width_request = width
      @popover.height_request = height
      return

    native = @widget\get_native!
    display = @widget\get_display!
    monitor = display\get_monitor_at_surface native\get_surface!
    geom = monitor\get_geometry!

    if @x + width > (geom.width - @comfort_zone)
      width = geom.width - @x - @comfort_zone

    if @y + height > (geom.height - @comfort_zone)
      height = geom.height - @y - @comfort_zone

    width, height = floor(width), floor(height)
    @width, @height = width, height
    @_set_offset width
    @popover\set_size_request width, height

  center: =>
    error('Attempt to center a closed popup', 2) if not @showing
    height = @height
    width = @width
    comfort = @comfort_zone * 2

    w_width, w_height = @widget.allocated_width, @widget.allocated_height

    -- are we too wide?
    if width + comfort > w_width
      width = w_width - comfort

    -- -- are we too tall?
    if height + comfort > w_height
      height = w_height - comfort

    @popover\set_size_request width, height

    -- we're small enough size wise, let's place us where we should be
    x = (w_width / 2) - (width / 2)
    y = (w_height / 2) - (height / 2)

    @popover.position = Gtk.POS_BOTTOM
    @pointing_to = {:x, :y, width: 1, height: 1}
    @popover.pointing_to = @pointing_to
    @popover\set_offset(width / 2, 0)

  _set_offset: (width) =>
    x_off = floor width / 2
    @popover\set_offset x_off, 0

return Popup
