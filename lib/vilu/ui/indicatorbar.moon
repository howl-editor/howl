import Gtk from lgi

class IndicatorBar
  new: (cls, border_width) =>
    error('Missing argument #1 (id)', 2) if not cls
    @container = Gtk.EventBox {
      Gtk.Box {
        id: 'box'
        orientation: 'HORIZONTAL'
        :border_width
        spacing: 10
        height_request: 20
      }
    }
    @container\get_style_context!\add_class cls
    @box = @container.child.box
    getmetatable(self).__to_gobject = => @container

  add: (position, indicator) =>
    pack = nil
    switch position
      when 'left'
        pack = @box\pack_start
      when 'right'
        pack = @box\pack_end
      else error 'Illegal indicator position "' .. position .. '"', 2

    pack indicator, false, false, 0

  get_gobject: => @container

return IndicatorBar
