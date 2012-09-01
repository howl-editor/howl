import Gtk from lgi
import Delegator from lunar.aux.moon
import Status, Readline from lunar.ui

class Window extends Delegator
  new: (properties = {}) =>
    props = { }
    props[k] = v for k,v in pairs properties

    @status = Status!
    @readline = Readline self

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
        spacing: 3,
        { expand: true, @grid },
        @status\to_gobject!,
        @readline\to_gobject!
      }
    }

    @win = Gtk.Window props
    @win.on_set_focus = -> _G.window = self
    @win\add alignment
    super @win

  to_gobject: => @win

  add_view: (view) =>
    gobject = if view.to_gobject then view\to_gobject! else view
    gobject.hexpand = true
    @grid\add gobject
    gobject\show_all!

return Window
