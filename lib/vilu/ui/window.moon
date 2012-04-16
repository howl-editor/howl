import Gtk from lgi
import Delegator from vilu.aux.moon

class Window extends Delegator
  new: (properties) =>
    super Gtk.Window properties

  add_view: (view) =>
    mt = getmetatable view
    widget = if mt and mt.__towidget then mt.__towidget(view) else view
    self\add(widget)

return Window
