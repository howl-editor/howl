---
title: howl.ui.CommandPanel
---

# howl.ui.CommandPanel

## Overview

A `CommandPanel` object is attached to every [Window] and manages the command
line that appears at the bottom of the window to handle user input. The
`CommandPanel` for the primary window is available at
`howl.app.window.command_panel`.

The recommended way to invoke and control the command panel is by using one of
the [built-in interactions](../interact.md). The command panel API can also be
used directly for finer control of the command line. This API is described in
this page.

## Example

Here is an example showing use of the command panel to display a prompt and
read user entered text:

```lua
TextReader = {}
function TextReader:init(command_line)
  self.command_line = command_line
  command_line.prompt = 'Name:'
  command_line.title = 'Please enter your name'
end

TextReader.keymap = {}
function TextReader.keymap:enter()
  self.command_line:finish(self.command_line.text)
end

function TextReader.keymap:escape()
  self.command_line:finish()
end

howl.app.window.command_panel:run(TextReader)
```

The same example rewritten in Moonscript is below:
```moonscript
class TextReader
  new: (opts={}) =>
    @opts = moon.copy opts

  init: (@command_line) =>
    @command_line.prompt = @opts.prompt
    @command_line.title = @opts.title

  keymap:
    enter: =>
      @command_line\finish @command_line.text

    escape: => @command_line\finish!

howl.app.window.command_panel\run TextReader(prompt: 'Name:', title: 'Please enter your name')
```

The `command_panel.run` method is passed a table
containing a *command line definition*. The definition is executed by the
command panel. In this example, the following steps occur after `run` is called:

1. The command panel creates a *CommandLine* object.

2. A command line box is displayed on the bottom of the window.

3. The `init` function of the definition is invoked and passed the
   `CommandLine` object.
   Note that above the `init` function sets the `prompt` and `title` fields
   on the `CommandLine` object. These are part of the command line API and
   setting these fields immediately updates the displayed prompt and title.
   The `text` field is used to read or set the editable text in the command line.

4. After `init` returns, the command line enters an active state and handles
   events based on user input. For instance, when the user presses `enter`,
   the `keymap.enter` function on the definition is invoked. The command line
   stays active until the `command_line.finish` function is called. Note that
   above this is called in both `enter` and `escape` keypress handlers.

5. When the user presses enter or escape, the `command_line.finish` method is
   called from the keymap handler. Then the command line is closed and the
   argument passes to the command_line is returned as the result of
   `command_panel.run`.

The above example shows a simple end-to-end execution of the command line. Note
that the API consists of two parts - the `CommandPanel` object and the
`CommandLine` object.

---

_See also_:

- The [interact](../interact.html) module for more information about
interactions
- The [spec](../../spec/ui/command_panel_spec.html) for CommandPanel

## CommandPanel

The `CommandPanel` only has one method called `run`.

### run(def, opts)

Creates a `CommandLine`, displayes the command line, and invokes the `def`
command line definition. `def` is table that provides the following fields:

* `init(command_line, opts)` (required function): Invoked on command line
initializaiont. `command_line` is the `CommandLine` object and `opts` is the
`opts` object passed into the `run` method. Typically this function saves the
`command_line` so it can use the CommandLine API (described below) while
handling keypresses or text changes.

* `keymap` (required table): Defines the keypress handling routines for the
command line. The keys are key names (such as `enter`) and the values are
functions that get called when the corresponding key is pressed. This is similar
to other keymaps in Howl, see [bindings](../bindings.md) for more details.

* `on_text_changed(text)` (optional function): Invoked whenever the user types
something and the editable text in the command line changes.

The `opts` table may provide the following fields:

* `text`: The intial value for the editable command line text.
* `help`: A [HelpContext](help_context.md) containing help for this invocation.
  The help is automatically displayed if the user presses `f1` while the command
  line is active.

## CommandLine

A command line widget contains many parts:

* the title displayed at the top in the title bar
* an edit box displayed for user text entry
* a prompt containing read-only text displayed to the left in the edit box
* any other widgets added using `add_widget` displayed between the title and the edit box

This composite widget is controlled using the following properties and methods:

## Properties (CommandLine)

### text

Gets or sets the editable text of the command line widget.

### prompt

Gets or sets the prompt shown in the command line. The prompt is some text
displayed to the left of the editable part of the widget.

### title

Gets of sets the title shown just at the top of the widget.

### notification

A [NotificationWidget](notification_widget.md) attached to the command line. To
display a message call:

```
command_line.notification\info 'hello'
```

## Methods (CommandLine)

### clear()

Clears the command line editable text.

### write(text)

Writes `text` into the editable text.

### finish(result)

Closes the command line and returns the original `CommandPanel.run` function
call. The result passed into finish is returned as the result of `run`.

### add_widget (name, widget)

Adds a custom widget `widget` in the command line view. `name` is the name used
to identify the widget. Currently two types of widgets are available - widgets
must be an instance of either [ListWidget] or [NotificationWidget].

### remove_widget (name)

Removes the widget identified by `name` from the command line view.

[interactions]: ../interact.html
[ListWidget]: list_widget.html
[NotificationWidget]: notification_widget.html
[Window]: window.html
