import Gtk from lgi
import Delegator from vilu.aux.moon
import Status from vilu.ui

class Window extends Delegator
  new: (properties = {}) =>
    props = { }
    props[k] = v for k,v in pairs properties

    @status = Status!

    @grid = Gtk.Grid
      row_spacing: 4
      column_spacing: 4
      column_homogeneous: true
      row_homogeneous: true

    alignment = Gtk.Alignment {
      top_padding: 5,
      left_padding: 5,
      right_padding: 5,
      bottom_padding: 5,
      Gtk.Box {
        orientation: 'VERTICAL',
        { expand: true, @grid },
        @status\to_gobject!
      }
    }

    @win = Gtk.Window props
    @win\add alignment
    super @win

  add_view: (view) =>
    gobject = if view.to_gobject then view\to_gobject! else view
    gobject.hexpand = true
    @grid\add gobject

return Window
