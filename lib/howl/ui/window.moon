import Gtk from lgi
import Delegator from howl.aux.moon
import Status, Readline from howl.ui
import signal from howl

class Window extends Delegator
  new: (properties = {}) =>
    props = type: Gtk.WindowType.TOPLEVEL
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
    @win.on_focus_in_event = self\_on_focus
    @win.on_focus_out_event = self\_on_focus_lost
    @win\add alignment
    @win\get_style_context!\add_class 'main'

    @is_fullscreen = false

    super @win

  to_gobject: => @win

  add_view: (view) =>
    gobject = if view.to_gobject then view\to_gobject! else view
    gobject.hexpand = true
    @grid\add gobject
    gobject\show_all!

  fullscreen: =>
    @win\fullscreen!
    @is_fullscreen = true

  unfullscreen: =>
    @win\unfullscreen!
    @is_fullscreen = false

  toggle_fullscreen: =>
    if @is_fullscreen then @unfullscreen!
    else @fullscreen!

  _on_focus: =>
    _G.window = self
    signal.emit 'window-focused', window: self
    false

  _on_focus_lost: =>
    signal.emit 'window-defocused', window: self
    false

-- Signals
signal.register 'window-focused',
  description: 'Signaled right after a window has recieved focus'
  parameters:
    window: 'The window that recieved focus'

signal.register 'window-defocused',
  description: 'Signaled right after a window has lost focus'
  parameters:
    window: 'The window that lost focus'

return Window
