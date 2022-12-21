-- Copyright 2012-2022 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
import signal from howl

class Status
  new: =>
    @label = Gtk.Label {
      xalign: 0
      wrap: true
    }
    @label.css_classes = {'status'}
    @level = nil
    signal.connect 'key-press', self\clear

  info: (text) => @_set 'info', text
  warning: (text) => @_set 'warning', text
  error: (text) => @_set 'error', text
  traceback: (text) => @_set 'error', text

  to_gobject: => @label

  clear: =>
    if @text
      if @level
        @_remove_css_class 'status_' .. @level

      @label.label = ''
      @level = nil
      @text = nil

  hide: =>
    @label.visible = false

  show: =>
    @label.visible = true

  _set: (level, text) =>
    if @level and level != @level
        @_remove_css_class 'status_' .. @level

    @label.css_classes = {'status', 'status_' .. level}
    @label.label = text
    @text = text
    @level = level

  _remove_css_class: (cls) =>
      classes = [c for c in *@label.css_classes when c != cls]
      @label.css_classes = classes

return Status
