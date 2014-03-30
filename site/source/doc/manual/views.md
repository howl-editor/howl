---
title: Using multiple views
---

# Using multiple views

## Overview

When you start Howl, you'll be presented with one window, containing one editor
view. Assuming there is sufficient screen estate to spare, it's often desirable
to have multiple views open in the same window, which let's you view one or more
buffers simultaneously. This is supported in Howl, where windows can contain an
arbitrary number of views, arranged in a grid pattern.

![Multiple views](/images/doc/multi-views.png)

In the above picture you have two editors in the first row, each occupying one
column each. In the bottom row you see one editor view occupying two columns.
While the most you'll likely ever want is around two or three separate view, you
can divide windows up in unreasonable ways should you so desire:

![Lots of views](/images/doc/lots-of-views.png)

There is currently no way to manually resize views; views are reflowed to fill
the entire window, and will occupy the maximum amount of space available to
them.

## View commands

Below is a list of some useful commands that work with views:

### Creating views

- `view-new-right-of`: Creates a new view, right of the current one.
- `view-new-left-of`: Creates a new view, left of the current one.
- `view-new-above`: Creates a new view, above the current one.
- `view-new-below`: Creates a new view, below the current one.

### Navigating views

- `view-left`: Moves focus to the view left of the current one.
- `view-right`: Moves focus to the view right of the current one.
- `view-up`: Moves focus to the view above the current one.
- `view-down`: Moves focus to the view below the current one.
- `view-next`: Moves focus to the next view in the grid. Bound to `ctrl_tab`
in the default keymap.

Each of the four directional commands above (view-left, view-right, view-up and
view-down) have two additional companion commands:

- `view-<direction>-wraparound`

These commands will wrap around the grid if no view could be found in the
specified direction. The _view-right-wraparound_ command for instance would go
to the view to the right, should it exist. If not, it would go to first view in
the next row should that exist, and to the first view of the first row if not.

- `view-<direction>-or-create`

These will automatically create a new view in the specified direction, if
necessary. For instance, the _view-right-or-create_ command would go to the view
to the right if there was a view to the right. Should no such view exist
however, it would be created first. The last set of commands are bound to
`shift_alt_left` + \<arrow key\> in the default keymap.

### Manipulating views

- `view-close`: Closes/removes the current view. Bound to `ctrl_w` in the
default keymap.

---

*Next*: [What's next?](next.html)
