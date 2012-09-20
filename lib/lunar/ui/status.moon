import Gtk from lgi
import signal from lunar

class Status
  new: =>
    @label = Gtk.Label {
      xalign: 0
      wrap: true
    }
    @label\get_style_context!\add_class 'status'
    @level = nil
    signal.connect 'key-press', self\clear

  info: (text) => @_set 'info', text
  warning: (text) => @_set 'warning', text
  error: (text) => @_set 'error', text

  clear: =>
    if @text
      @label.label = ''
      @level = nil
      @text = nil

  to_gobject: => @label
  hide: => @label.visible = false
  show: => @label.visible = true

  _set: (level, text) =>
    @label\get_style_context!\add_class 'status_' .. level
    @label\get_style_context!\remove_class 'status_' .. @level if @level
    @label.label = text
    @text = text
    @level = level

return Status
