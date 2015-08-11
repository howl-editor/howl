-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gtk = require 'ljglibs.gtk'

class IndicatorBar
  new: (cls, border_width) =>
    error('Missing argument #1 (id)', 2) if not cls
    @box = Gtk.Box {
      :border_width
      spacing: 10
      height_request: 20
    }
    @container = Gtk.EventBox { @box }
    @container.style_context\add_class cls
    @indics = {}
    getmetatable(self).__to_gobject = => @container

  add: (position, id, widget) =>
    pack = nil
    switch position
      when 'left'
        pack = @box\pack_start
      when 'right'
        pack = @box\pack_end
      else error 'Illegal indicator position "' .. position .. '"', 2

    indicator = self._create_indicator id, widget
    @indics[id] = indicator
    pack indicator, false, false, 0
    indicator

  remove: (id) =>
    indicator = @indics[id]
    indicator\destroy! if indicator

  to_gobject: => @container

  _create_indicator: (id, widget) ->
    widget or= Gtk.Label single_line_mode: true
    with widget.style_context
      \add_class 'indic_default'
      \add_class 'indic_' .. id

    widget\show!
    widget

return IndicatorBar
