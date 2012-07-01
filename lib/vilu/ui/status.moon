import Gtk from lgi
import signal from vilu

class Status
  new: =>
    @label = Gtk.Label {
      use_markup: true
      xalign: 0
    }
    @label\get_style_context!\add_class 'status'
    @level = nil
    signal.connect 'key-press', self\clear

  info: (text) => self\_set 'info', text
  warning: (text) => self\_set 'warning', text
  error: (text) => self\_set 'error', text

  clear: =>
    if @text
      @label.label = ''
      @level = nil
      @text = nil

  to_gobject: => @label

  _set: (level, text) =>
    @label\get_style_context!\add_class 'status_' .. level
    @label\get_style_context!\remove_class 'status_' .. @level if @level
    @label.label = text
    @text = text
    @level = level

return Status
