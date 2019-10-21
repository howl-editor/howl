-- Copyright 2012-2015 The Howl Developers
-- License: MIT (see LICENSE.md at the top-level directory of the distribution)

Gdk = require 'ljglibs.gdk'
Gtk = require 'ljglibs.gtk'
ffi = require 'ffi'
gobject_signal = require 'ljglibs.gobject.signal'
Background = require 'ljglibs.aux.background'
{:PropertyObject} = howl.util.moon
{:Activity, :CommandPanel, :Status, :theme} = howl.ui
{:signal} = howl
{:config, :signal} = howl

append = table.insert
ffi_cast = ffi.cast

to_gobject = (o) ->
  status, gobject = pcall -> o\to_gobject!
  return status and gobject or o

placements = {
  left_of: 'POS_LEFT'
  right_of: 'POS_RIGHT'
  above: 'POS_TOP'
  below: 'POS_BOTTOM'
}

GTK_SUPPORTS_HIDDEN_TITLEBAR = not Gtk.check_version(3, 4)

class Window extends PropertyObject
  new: (properties = {}) =>
    @_handlers = {}
    @status = Status!
    @command_panel = CommandPanel self
    @background = Background "window_bg", 0, 0
    @grid = Gtk.Grid
      column_homogeneous: true
      row_homogeneous: true

    @activity = Activity!
    @widgets = Gtk.Box Gtk.ORIENTATION_VERTICAL
    @box = Gtk.Box Gtk.ORIENTATION_VERTICAL, {
      { expand: true, @grid },
      @command_panel\to_gobject!
      @widgets,
      @status\to_gobject!,
    }
    @bg_box = Gtk.Box Gtk.ORIENTATION_VERTICAL, {
      { expand: true, @box }
    }

    @win = Gtk.Window Gtk.Window.TOPLEVEL
    @win[k] = v for k,v in pairs properties

    if GTK_SUPPORTS_HIDDEN_TITLEBAR
      @win.hide_titlebar_when_maximized = config.hide_titlebar_when_maximized

      config.watch 'hide_titlebar_when_maximized', (_, value) ->
        @win.hide_titlebar_when_maximized = value

    append @_handlers, @bg_box\on_size_allocate self\_on_bg_size_allocate
    append @_handlers, @bg_box\on_draw self\_on_bg_draw
    append @_handlers, @win\on_focus_in_event self\_on_focus
    append @_handlers, @win\on_focus_out_event self\_on_focus_lost
    append @_handlers, @win\on_destroy self\_on_destroy
    append @_handlers, @win\on_screen_changed self\_on_screen_changed
    @win.app_paintable = true
    @_set_alpha!

    @win\add @bg_box

    @_theme_changed = self\_on_theme_changed
    signal.connect 'theme-changed', @_theme_changed
    @data = {}
    @_on_theme_changed theme: theme.current
    super @win

  @property views: get: =>
    views = {}

    for c in *@grid.children
      props = @grid\properties_for c
      append views, {
        x: props.left_attach + 1
        y: props.top_attach + 1
        width: props.width
        height: props.height
        view: c
      }

    table.sort views, (a, b) ->
      return a.y < b.y if a.y != b.y
      a.x < b.x

    views

  @property focus_child: get: =>
    fc = @grid.focus_child
    @data.focus_child = nil if fc
    fc or @data.focus_child

  @property current_view: get: =>
    focused = @focus_child
    return nil unless focused
    @get_view focused

  @property fullscreen:
    get: => @win.window and @win.window.state.FULLSCREEN

    set: (state) =>
      if state and not @fullscreen
        @win\fullscreen!
      elseif not state and @fullscreen
        @win\unfullscreen!

  @property maximized:
    get: => @win.window and @win.window.state.MAXIMIZED

    set: (state) =>
      if state and not @maximized
        @win\maximize!
      elseif not state and @maximized
        @win\unmaximize!

  add_widget: (widget) =>
    @widgets\pack_end widget, true, true, 0

  remove_widget: (widget) =>
    @widgets\remove widget

  siblings: (view, wraparound = false) =>
    current = @get_view to_gobject(view or @focus_child)
    views = @views
    return {} unless current and #views > 1

    local left, right, up, down, index
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

  remember_focus: =>
    @data.focus_child = @grid.focus_child

  get_screenshot: (opts={}) =>
    x, y, w, h = 0, 0, @allocated_width, @allocated_height
    window = @window

    if opts.with_overlays
      x, y = window\get_position!
      window = @screen.root_window

    Gdk.Pixbuf.get_from_window window, x, y, w, h

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

        with @grid\properties_for(widget)
          .left_attach = i * col_size
          .top_attach = y - 1
          .width = width

  _insert_column: (anchor, where) =>
    rel_column = @grid\properties_for(anchor).left_attach
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
    @grid\attach_next_to gobject, anchor, Gtk[where], 1, 1

  _on_theme_changed: (opts) =>
    def = {}
    outer_padding = 5
    inner_padding = 4
    if opts.theme and opts.theme.window
      with opts.theme.window
        def = .background or def
        outer_padding = .outer_padding or outer_padding
        inner_padding = .inner_padding or inner_padding

    @box.margin = outer_padding
    @box.spacing = inner_padding
    with @grid
      .row_spacing = inner_padding
      .column_spacing = inner_padding

    @background\reconfigure def
    @win\queue_draw!

  _on_bg_size_allocate: (_, alloc) =>
    alloc = ffi_cast('GdkRectangle *', alloc)
    @background\resize alloc.width, alloc.height

  _on_destroy: =>
    -- disconnect signal handlers
    for h in *@_handlers
      gobject_signal.disconnect h

    signal.disconnect 'theme-changed', @_theme_changed

  _on_bg_draw: (_, cr) =>
    cr\save!
    @background\draw cr
    cr\restore!
    false

  _on_focus: =>
    howl.app.window = self
    signal.emit 'window-focused', window: self
    false

  _on_focus_lost: =>
    signal.emit 'window-defocused', window: self
    false

  _set_alpha: =>
    screen = @win.screen
    if screen.is_composited
      visual = screen.rgba_visual
      @win.visual = visual if visual

  _on_screen_changed: =>
    @_set_alpha!

if GTK_SUPPORTS_HIDDEN_TITLEBAR
  config.define
    name: 'hide_titlebar_when_maximized'
    description: 'Whether to hide the titlebar when maximized'
    scope: 'global'
    type_of: 'boolean'
    default: true

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
