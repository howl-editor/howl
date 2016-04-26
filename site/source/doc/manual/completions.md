---
title: Using Howl completions
---

# Using Howl completions

## Overview

Howl is strongly in favor of completions, and will offer them whenever and
wherever possible. This section aims to provide an overview of Howl completions
work, and how to use them for best effect. Alternatively, if you consider
auto-completions a nuisance and would like to cut down on them you'll learn how
to do that here as well.

## Using completions

### Interacting with completions

There are currently two different places where you'll encounter completions: In
editors while editing text, and in the command line while entering commands. While
the completions offered differs as one would expect, the way you interact with a
completion list is the same:

- You can press `enter` to accept the completion given. This will cause the
  currently selected completion to be inserted at the cursor. The completion will
  either be simply inserted at the cursor, or it will optionally replace the
  current word. This behaviour is controlled by the `hungry_completion`
  configuration variable.

- You can press `escape` to remove the completion list.

- You can continue typing, which will update the available completions. One
  reason for this is that you want to narrow down the list of completions
  so that the desired completion becomes selected, and choosable by the `enter`
  key. Another is that the desired completion is not currently in the list of
  completions. Completions in Howl are not "static", but are updated each
  time you type. So the initial list of alternatives are not necessarily
  the only alternatives for completion. We'll see next how completions are
  matched which will give you an idea of how to utilize this for less typing.

- You can navigate the current list of completions manually and choose one.
  Pressing `down` or `ctrl_n` will move down the list, while `up` and `ctrl_p`
  will move up the list. `page_up` will move one page up, and `page_down` will
  move one page down.

When completing, Howl will try to match your input string against the available
completions in two ways: _Exact matching_ and _boundary matching_. An exact
match means that your input string is found as-is in the completion. A boundary
match means that all parts of your input string matches at one or more
boundaries in the completion, typically defined as underscores, slashes, etc.
The below image illustrates the two different types of matches for a completion
list:

![Completion types](/images/screenshots/monokai/completion-types.png)

In the above example we can see that "aa" matches "attr_accessor" as a boundary
match, while "mraardvark" is an exact match. The order of the completions above
is no coincidence - boundary matches are preferred over exact matches.

*Finally, a note about a gotcha:*

As long as a completion list is showing, `enter` will always select the active
completion. This is typically what you want. However, at times you just want add
a new line, or enter the text as written. To avoid selecting the completion,
enter `escape` to close the completion list first.

### Configuring completions

Here are some configuration variables you might want to tweak in order to
control completions:

- **complete**:

Controls the mode of how completions are started. This is of interest
particularly if you want turn off automatically shown completion lists. If you
turn it off, you will have to explicitly request completions using the
`editor-complete` command for editors (bound to `ctrl_space` by default) or by
pressing `tab` in the command line.

- **completion_max_shown**:

Controls the number of completions shown in the completion list.

- **hungry_completion**:

Whether a selected completion will replace the current word or not.

- **completion_popup_after**:

When auto-complete is one, this variable controls after how many characters the
completion list should pop up after.

- **completion_skip_auto_within**:

This variable, unset by default, contains a list of style patterns where the
completion list should not automatically pop up.

- **inbuffer_completion_max_buffers**:

For the in-buffer completer, this controls the number of open buffers that are
consulted for completions.

- **inbuffer_completion_same_mode_only**:

For the in-buffer completer, this controls whether only open buffers with the
same mode as the current one is consulted or not.

*Next*: [Working with files](files.html)
