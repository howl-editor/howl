---
title: howl.ui.CommandLine
---

# howl.ui.CommandLine

Instances of `CommandLine` are used to control the command line widget while
obtaining user input in Howl. Each [Window] instance has an associated
[.command_line](window.html#command_line) field which is used to access the
command line instance.

[Interactions] work closely with the command line to obtain user input.
Interactions are run by the command line and the command line API is used from
within a running interaction to update things like the displayed prompt. When no
interaction is running the command line functionality is not available.

The command line maintains a stack of running interactions. Whenever an
interaction is invoked, the new interaction is *pushed* onto the stack of
running interactions. When an interaction finishes, it is popped off the stack.
The command line maintains state for each running interaction independently. The
topmost interaction on the stack is called the *active* interaction.

The command line view contains the following widgets:

- Command text entry: This is the primary text input widget that holds the
cursor while the command line is displayed. It shows both the *prompt* and the
*text*. The *prompt* is text set via code that is not user editable and
displayed before the *text*, which is editable text entered by the user. When
multiple interactions are running, the prompt and text for each is displayed
from left to right, however only the active interaction text (i.e. the rightmost
text) is editable.

- Title bar: This contains an optional title for the command line view. See
[`title`](#title).

- Notification bar: This displays notification messages. See
[`notify`](#notify).

- Custom widgets: Widgets such as [ListWidget] or [NotificationWidget] can be
displayed using [`add_widget`](#add_widget) and
[`remove_widget`](#remove_widget).

---

_See also_:

- The [interact](../interact.html) module for more information about
interactions
- The [spec](../../spec/ui/command_line_spec.html) for CommandLine

## Properties

### prompt

The prompt shown in the command line. This property gets or sets the prompt for
the active interaction. Read/write.

### text

The user editable text currently in the command line. This property gets or sets
the text for the active interaction. Read/write.

### title

The title of the CommandLine view. This property only gets or sets the title for
the active interaction. Read/write.

## Methods

### add_widget (name, widget)

Adds a custom widget `widget` in the command line view. `name` is the name used
to identify the widget. Widgets added are associated with the active interaction
and when the active interaction finishes, the associated widgets are
automatically removed. Currently two types of widgets are available - widgets
must be an instance of either [ListWidget] or [NotificationWidget]. Widgets may
provide their own [keymap](../bindings.html). The keymap for the active
interaction takes precedence over keymaps for the attached widgets.

### clear ()

Clears the text part of the command line. The prompt is left intact.

### clear_all ()

Clears the entire command line, including any prompts and texts from other
running interactions. When the active interaction exits, the prompts and texts
from other running interactions are automatically restored.

### clear_notification ()

Clears any notification messages displayed, if any, and hides the notification
bar.

### notify (text, level='info')

Shows the notification bar containing the `text` message. The `level` can be
'info', 'warn' or 'error' and the message is styled accordingly.

### pop_spillover ()

Returns and clears any unprocessed spillover text. See
[write_spillover](#write_spillover) for a description of spillover.

### remove_widget (name)

Removes the widget identified by `name` from the command line view.

### write (text)

Appends `text` to the current text in the command line. This affects the text
for the active interaction only.

### write_spillover (text)

Saves `text` as the current *spillover*. The spillover is the part of the text
that is left unprocessed by the current interaction but may be processed by
another interaction that is invoked. There is only one spillover for the command
line.

For example, if the text 'open path/to/folder' is pasted into the command line,
the active interaction may only process 'open' and write 'path/to/folder' to
spillover before invoking other interactions. An invoked interaction might then
use `pop_spillover` to retrieve 'path/to/folder' and process it.

[interactions]: ../interact.html
[ListWidget]: list_widget.html
[NotificationWidget]: notification_widget.html
[Window]: window.html
