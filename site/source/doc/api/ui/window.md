---
title: howl.ui.Window
---

# howl.ui.Window

Windows are the primary top-level user interface components in Howl. They can
hold an arbitrary number of other user interface components within, called
"views", which are all ordered in a grid. The most common examples of such a
views are of course [Editor] instances, but it's possible to place various other
types of graphical components in a Window, although there are currently no
examples of this.

A window has, apart from the grid components described above, always two
graphical elements associated with it; A [Status] instance used for displaying
informational message to the user, and a [CommandLine] instance allowing for
user input. It can also optionally display arbitrary widgets at the bottom via
the use of [push_widget].

The currently focused window is accessible as
[Application.window](../application.html#window).

A Window delegates to the corresponding Gtk Window, which means that you can
access GtkWindow properties and methods directly on the Window instance. For
example:

```lua
howl.app.window.accept_focus -- => true
howl.app.window:get_default_size() -- => 1920, 1056
```

_See also_:

- The [spec](../../spec/ui/window_spec.html) for Window

## Properties

### command_line

A [CommandLine] instance associated with the window.

### current_view

The currently focused view. The return value is a table with same fields as is
documented in [views](#views).

### focus_child

The currently focused Gtk view within the window.

### fullscreen

A boolean indicating whether the window is fullscreen or not. Assign to this to
force a particular state.

### maximized

A boolean indicating whether the window is maximized or not. Assign to this to
force a particular state.

### status

A [Status] instance associated with the window.

### views

A list of view information for the currently existing views in the window grid.
Each element is a table with the following fields:

- `x`: The horizontal position of the view in the grid (1-based)
- `y`: The vertical position of the view in the grid (1-based)
- `width`: The number of horizontal grid squares the view spans
- `height`: The number of vertical grid squares the view spans
- `view`: A reference to the Gtk view

The returned list is sorted in left-to-right, top-to-bottom order.

Note that the `view` field, as the documentation says, holds a reference to the
"Gtk view". This means that you cannot expect this to be, for instance, a
reference to an [Editor]. Should you need to map a particular view to an
[Editor] instance, you could instead iterate through
[Application.editors](../application.html#editors) and see whether an Editor's
[to_gobject](editor.html#to_gobject) corresponds to the `view` field.

## Methods

### add_view (view, placement = 'right_of', anchor = @focus_child)

Adds `view` to the grid. If `view` is not a Gtk view, it's automatically cast
using the view's `to_gobject`, if it's present. `placement` specifies where to
place the view in the grid, relative to `anchor` which should be an existing
view in the grid. Valid values for `placement` are:

- `left_of`: Places the view left of `anchor`
- `right_of`: Places the view right of `anchor`.
- `above`: Places the view above `anchor`.
- `below`:Places the view below `anchor`.

### add_widget (widget)

Adds the specified widget `widget` to the window's widget area (lower part).
Call [remove_widget] to remove the widget later.

### get_view (o)

Gets the view information for the object `o`. The return value is a table with
same fields as is documented in [views](#views). Returns `nil` if `o` is not in
the window grid.

### remember_focus ()

Remember the currently focused view as the focussed view until the focus
switches to another view in the grid. This means even when the focus switches to
a view outside the grid, peroperties and methods that use the current view - for
example, [`current_view`](#current_view) - will continue to use the remembered
view.

### remove_view (view = nil)

Removes the specified `view`, or the currently focused view if not specified,
from the grid.

### remove_widget (widget)

Removes the specified widget `widget` (which should have been previously added
using [add_widget]) from the window's widget area.

### siblings (view, wraparound = false)

Returns a a table of siblings for `view`, which should be a Gtk view. The
returned table contains four values accessible through the keys `up`, `down`,
`left` and `right`. Each value is a table with same fields as is documented in
[views](#views).

`wraparound` controls what is returned if no sibling is found for a particular
direction. If it's `false`, as is the default, `nil` is returned if no sibling
can be found for a particular direction. If it's `true`, then the search for
siblings will wrap around in a left-to-right, top-to-bottom order fashion.

### to_gobject ()

Returns the underlying Gtk window.

[CommandLine]: command_line.html
[Editor]: editor.html
[Status]: status.html
[push_widget]: #push_widget
[remove_widget]: #remove_widget
