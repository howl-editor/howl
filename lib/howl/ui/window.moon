import Gtk from lgi
import PositionType from Gtk
import PropertyObject from howl.aux.moon
import Status, Readline from howl.ui
import signal from howl

to_gobject = (o) ->
  status, gobject = pcall -> o\to_gobject!
  return status and gobject or o

placements = {
  left_of: 'LEFT'
  right_of: 'RIGHT'
  above: 'TOP'
  below: 'BOTTOM'
}

class Window extends PropertyObject
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

    @_is_fullscreen = false
    @data = {}

    super @win

  @property views: get: =>
    props = @grid.property
    views = {}

    for c in *@grid\get_children!
      append views, {
        x: props[c].left_attach + 1
        y: props[c].top_attach + 1
        width: props[c].width
        height: props[c].height
        view: c
      }

    table.sort views, (a, b) ->
      return a.y < b.y if a.y != b.y
      a.x < b.x

    views

  @property focus_child: get: =>
    fc = @grid\get_focus_child!
    @data.focus_child = nil if fc
    fc or @data.focus_child

  @property current_view: get: =>
    focused = @focus_child
    return nil unless focused
    @get_view focused

  @property fullscreen:
    get: => @_is_fullscreen

    set: (status) =>
      if status and not @_is_fullscreen
        @win\fullscreen!
        @_is_fullscreen = true
      elseif not status and @_is_fullscreen
        @win\unfullscreen!
        @_is_fullscreen = false

  siblings: (view, wraparound = false) =>
    current = @get_view to_gobject(view or @focus_child)
    views = @views
    return {} unless current and #views > 1

    local left, right, up, down, index
    gobject = to_gobject view
    vertical_siblings = {}

    for i = 1, #views
      v = views[i]
      if v.view == current.view
        index = i
      elseif v.x <= current.x and v.x + v.width > current.x
        if v.y == current.y - 1
          up = v.view
        elseif v.y == current.y + 1
          down = v.view

        append vertical_siblings, v.view

    before = views[index - 1]
    left = if before and before.y == current.y then before

    after = views[index + 1]
    right = if after and after.y == current.y then after

    if wraparound
      left or= before or views[#views]
      right or= after or views[1]
      up = vertical_siblings[#vertical_siblings] unless up
      down = vertical_siblings[1] unless down

    {
      left: left and left.view
      right: right and right.view
      :up
      :down
    }

  to_gobject: => @win

  add_view: (view, placement = 'right_of', anchor) =>
    gobject = to_gobject view
    @_place gobject, placement, anchor
    gobject\show_all!
    @_reflow!
    @get_view gobject

  remove_view: (view = nil) =>
    view = @focus_child unless view
    gobject = to_gobject view
    error "Missing view to remove", 2 unless gobject

    siblings = @siblings gobject
    focus_target = siblings.right or siblings.left
    focus_target or= @siblings(gobject, true).left
    gobject\destroy!
    @_reflow!
    focus_target\grab_focus! if focus_target

  get_view: (o) =>
    gobject = to_gobject o
    for v in *@views
      return v if v.view == gobject

    nil

  toggle_fullscreen: => @fullscreen = not (@fullscreen == true)

  _remember_focus: =>
    @data.focus_child = @grid\get_focus_child!

  _as_rows: (views) =>
    rows = {}
    row = {}
    current = nil

    for v in *views
      if current and v.y != current.y
        append rows, row
        row = {}

      current = v
      append row, v.view

    append rows, row
    rows

  _reflow: =>
    views = @views
    return unless #views > 1

    props = @grid.property
    rows = @_as_rows views

    max_columns = 0
    max_columns = math.max(max_columns, #r) for r in *rows

    for y = 1, #rows
      row = rows[y]
      col_size = math.floor max_columns / #row
      extra = max_columns % #row
      for i = 0, #row - 1
        width = col_size
        width += extra if i == #row - 1
        widget = row[i + 1]

        with props[widget]
          .left_attach = i * col_size
          .top_attach = y - 1
          .width = width

  _insert_column: (anchor, where) =>
    rel_column = @grid.property[anchor].left_attach
    if where == 'left_of'
      @grid\insert_column rel_column
    else
      @grid\insert_column rel_column + 1

  _place: (gobject, placement, anchor) =>
    where = placements[placement]
    error "Unknown placement '#{placement}' specified", 2 unless where

    anchor = to_gobject(anchor) or @focus_child
    unless anchor
      @grid\add gobject
      return

    @_insert_column anchor, placement if placement == 'left_of' or placement == 'right_of'
    @grid\attach_next_to gobject, anchor, PositionType[where], 1, 1

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
