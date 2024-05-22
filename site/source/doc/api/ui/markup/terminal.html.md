---
title: howl.ui.markup.terminal
---

# howl.ui.markup.terminal

## Overview

The terminal module parses output geared towards terminals, and returns a
[StyledText] instance containing the result. The primary use of this is to parse
output containing ANSI escape sequences, particularly sequences concerning
colors or text attributes, and get something usable for displaying in an
[ActionBuffer].

--

_See also_:

- [StyledText]
- [ActionBuffer]
- The [spec](../../../spec/ui/markup/terminal_spec.html) for the terminal
module.


## Functions

### (output)

Parses the provided `output`, and returns a [StyledText] instance.

[ActionBuffer]: ../action_buffer.html
[StyledText]: ../styled_text.html
