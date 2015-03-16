-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
import signal from howl

class Status
  new: =>
    @label = Gtk.Label {
      xalign: 0
      wrap: true
    }
    @label.style_context\add_class 'status'
    @level = nil
    signal.connect 'key-press', self\clear

  info: (text) => @_set 'info', text
  warning: (text) => @_set 'warning', text
  error: (text) => @_set 'error', text

  to_gobject: => @label

  clear: =>
    if @text
      if @level
        @label.style_context\remove_class 'status_' .. @level

      @label.label = ''
      @level = nil
      @text = nil

  hide: =>
    @label.visible = false
  show: =>
    @label.visible = true

  _set: (level, text) =>
    if @level and level != @level
        @label.style_context\remove_class 'status_' .. @level if @level

    @label.style_context\add_class 'status_' .. level

    @label.label = text
    @text = text
    @level = level

return Status
