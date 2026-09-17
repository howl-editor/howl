---
title: howl.ui.HelpContext
---

# howl.ui.HelpContext

## Overview

A HelpContext is an object that contains help information presented to the user.
It is typically created to be passed to [interactions](../interact.md) and the
[CommandPanel](command_panel.md).

## Methods

### add_section(section)

Add a text section to this help object. The `section` argument is a table
containing `heading` and `text` fields, both of which should be strings.

### add_keys(key_defs)

Add keystroke information to this help object. The `key_defs` argument is a
dictionary that contains the keystroke as the key and the help text as the value. Here is an example:

```
help_context\add_keys
  ctrl_w: 'close this window'
  'cursor-down': 'select next element'
```

Note that the key can be either a keystroke name such as `ctrl_w` or a command
name such as `'cursor-down'`. When a command is specified, the displayed text
contains the shortcut keystroke associated with that command.

### get_buffer ->

Returns an [ActionBuffer](action_buffer.md) containing all the help information
added to this object.


### merge(other_help_context) ->

Merge all help information from `other_help_context` into this one.
