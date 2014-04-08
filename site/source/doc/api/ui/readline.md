---
title: howl.ui.Readline
---

# howl.ui.Readline

Readline instances are the primary way of obtaining user input in Howl. Each
[Window] instance has an associated [.readline](window.html#readline) field
which you'll use to access the readline instance. Note that while interacting
with a Readline instance directly is fine, you would typically write a [command]
instead, which manages the Readline handling for you.

_See also_:

- The [inputs] module for more information about inputs
- The [spec](../../spec/ui/readline_spec.html) for Readline

## Properties

### width_in_columns

Holds the width of the readline, in character columns. This only available when
the Readline is showing, and is nil otherwise.

### prompt

The prompt as shown in the Readline. Read/write.

### text

The text currently in the Readline. The text is defined as being everything in
the input line that is not part of the [prompt](#prompt). Read/write.

### title

The title of the Readline window. Read/write.

## Methods

### hide ()

Hides the Readline if it's currently showing. Done automatically by [read], and
thus not typically used.

### notify (text, style)

Causes `text` to be shown above the input line in the Readline. As the status
bar is hidden while the Readline is showing, this can be used to display
notifications to the user when in the readline. `style` optionally specifies the
style to use when displaying the text, and is one of the available styles from
[style](style.html).

### read (prompt, input = {}, opts = {})

Prompts the user for input. `prompt` will be displayed as the Readline prompt.
`input` specifies an optional "input" to use for controlling the user input.
`opts` is an optional table, which if passed may contain the following keys:

- `text`: The initial text to load into the Readline upon showing.

The method returns the value as input from the user, or `nil` if the user
cancels. Note that the type of the value returned is dependent on the `input`.

To understand how to utilize for best effect, read through the documentation for
[inputs].

### show ()

Shows the Readline if it's currently hidden. Done automatically by [read], and
thus not typically used.

### to_gobject ()

Returns the underlying Gtk widget.

[read]: #read
[Window]: window.html
[command]: ../command.html
[inputs]: ../inputs.html
