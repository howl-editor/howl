---
title: howl.ui.ListWidget
---

# howl.ui.ListWidget

## Overview

ListWidget is a graphical widget containing a [List] component. A ListWidget is
primarily used to display a selection list attached to the [command line]. For
example, the [interact.select](../interact.html#select) interaction uses the
ListWidget to display a selection list. It can be used wherever a graphical
component is expected, such as in a popup.

ListWidget handles keystrokes bound to the 'cursor-up', 'cursor-down',
'cursor-page-up' and 'cursor-page-down' commands to change the currently
selected item. The default keystrokes bound to these commands are the `up`,
`down` , `pgup` and `pgdn` keys respectively.

The ListWidget automatically adjusts it size to accommodate the content of the
associated list.

---

_See also_:

- The [List] component
- The [CommandLine] API
- The [spec](../../spec/ui/list_widget_spec.html) for ListWidget
- The [interact.select](../interact.html#select) interaction which displays a
selection list using ListWidget

## Constructor

### ListWidget (list, opts={})

Creates a new ListWidget.

- `list` is the list that the widget should display.

- `opts` is a table of options which can contain the following fields:

  - `auto_fit_width`: _[optional, default:false]_ When `true`, adjusts the width
of the widget to fit the list's content.

  - `never_shrink`: _[optional, default:false]_ When `true`, the widget ensures
that the list never shrinks, even if the list is updated to contain fewer items.
By default the height of the widget is adjusted to fit the space occupied by the
list.

## Properties

### height

The height of the widget.

### .max_height_request

The desired maximum height for the widget, in pixels. The height is rounded down
to the closest multiple of the line height, and is then used for specifying
[.max_rows](list.html#max_rows) for the associated list. Write only.

### .showing

`true` when the widget is currently showing or `false` when hidden. Read-only.

### width

The width of the widget.

## Methods

### hide ()

Hides the widget.

### show ()

Shows the widget.

[List]: list.html
[CommandLine]: command_line.html
[command line]: command_line.html
