import Gtk from lgi
import PropertyObject from lunar.aux.moon

screen_size = (widget) ->
  screen = widget\get_screen!
  width: screen\get_width!, height: screen\get_height!

class Popup extends PropertyObject
  comfort_zone: 10

  new: (child, properties = {}) =>
    error('Missing argument #1: child', 3) if not child

    properties.type = 'POPUP'
    properties.height = 150 if not properties.height
    properties.width = 150 if not properties.width
    @window = Gtk.Window properties
    box = Gtk.Box {
      orientation: 'VERTICAL',
      { expand: true, child }
    }
    @window\add box
    @showing = false
    super!

  show: (widget, options = position: 'center') =>
    @transient_for = widget\get_toplevel!
    @window\realize!

    if options.x
      @window.window_position = 'NONE'
      @move_to widget, options.x, options.y
    else
      @center widget

    @window\show_all!
    @showing = true

  close: =>
    @window\hide!
    @showing = false

  move_to: (widget, x, y) =>
    w_x, w_y = widget\get_toplevel!.window\get_position!
    t_x, t_y = widget\translate_coordinates(widget\get_toplevel!, x, y)
    x = w_x + t_x
    y = w_y + t_y

    screen = screen_size widget
    if x + @window.width > (screen.width - @comfort_zone)
      @window.width = screen.width - x - @comfort_zone

    if y + @window.height > (screen.height - @comfort_zone)
      @window.height = screen.height - y - @comfort_zone

    @window\move x, y

  center: (widget) =>
    height = @height
    width = @width

    -- now, if we were to center ourselves on the widgets toplevel,
    -- with our current width and height..

    screen = screen_size widget
    toplevel = widget\get_toplevel!
    w_x, w_y = toplevel.window\get_position!
    w_width, w_height = toplevel.width, toplevel.height
    win_h_center = w_x + (w_width / 2)
    win_v_center = w_y + (w_height / 2)
    x = win_h_center - (width / 2)
    y = win_v_center - (height / 2)

    -- are we outside of the comfort zone horizontally?
    if x < @comfort_zone or x + width > (screen.width - @comfort_zone)
      -- pull in the stomach
      min_outside_h = math.min(w_x, screen.width - (w_x + w_width))
      width = (w_width + min_outside_h) - @comfort_zone
      x = win_h_center - (width / 2)

    -- are we outside of the comfort zone vertically?
    if y < @comfort_zone or y + heigth > (screen.height - @comfort_zone)
      -- hunch down
      min_outside_v = math.min(w_y, screen.height - (w_y + w_height))
      height = (w_height + min_outside_v) - @comfort_zone
      y = win_v_center - (height / 2)

    -- now it's all good
    @window.height = height
    @window.width = width
    @window\move x, y

return Popup
