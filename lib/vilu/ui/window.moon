import Gtk from lgi
import Delegator from vilu.aux.moon

class Window extends Delegator
  new: (properties) =>
    props = { }

    props[k] = v for k,v in pairs properties
    @bin = Gtk.Alignment
      top_padding: 10,
      left_padding: 10,
      right_padding: 10,
      bottom_padding: 20
    @win = Gtk.Window props
    @win\add(@bin)
    super @win

  add_view: (view) =>
    mt = getmetatable view
    gobject = if mt and mt.__to_gobject then mt.__to_gobject(view) else view
    @bin\add(gobject)

return Window
