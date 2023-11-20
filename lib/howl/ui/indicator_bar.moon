-- Copyright 2012-2023 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'
Pango = require 'ljglibs.pango'

class IndicatorBar
  new: (cls) =>
    error('Missing argument #1 (id)', 2) if not cls
    middle_spacer = Gtk.Box Gtk.ORIENTATION_HORIZONTAL, hexpand: true
    @box = Gtk.Box Gtk.ORIENTATION_HORIZONTAL, {
      height_request: 20
    }
    @box\append middle_spacer
    @box.css_classes = {'indicator-bar', cls}
    @indics = {}

  add: (position, id, widget) =>
    pack = nil
    switch position
      when 'left'
        pack = @box\prepend
      when 'right'
        pack = @box\append
      else error 'Illegal indicator position "' .. position .. '"', 2

    indicator = self._create_indicator id, widget
    @indics[id] = indicator
    pack indicator, false, false, 0
    indicator

  remove: (id) =>
    indicator = @indics[id]
    indicator\destroy! if indicator

  to_gobject: => @box

  _create_indicator: (id, widget) ->
    widget or= Gtk.Label single_line_mode: true, ellipsize: Pango.ELLIPSIZE_MIDDLE
    widget.css_classes = { 'indicator', id }
    widget

return IndicatorBar
