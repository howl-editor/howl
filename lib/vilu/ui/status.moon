import Gtk from lgi

class Status
  new: =>
    @label = Gtk.Label {
      use_markup: true
      xalign: 0
    }
    @label\get_style_context!\add_class 'status'
    @level = nil

  info: (text) =>
    @label.label = text
    self\_set_level 'info'

  warning: (text) =>
    @label.label = text
    self\_set_level 'warning'

  error: (text) =>
    @label.label = text
    self\_set_level 'error'

  to_gobject: => @label

  _set_level: (level) =>
    @label\get_style_context!\add_class 'status_' .. level
    @label\get_style_context!\remove_class 'status_' .. @level if @level
    @level = level

return Status
