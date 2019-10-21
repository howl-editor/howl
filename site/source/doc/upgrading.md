# Upgrading to Howl 0.7

## Overview

A major backwards incompatible change in 0.7 is [The Command Interaction
Refactor](https://github.com/howl-editor/howl/wiki/The-Command-Interaction-Refactor).
This affects multiple modules, specially `command`, `interact` and
`command_line`. This document describes how to upgrade from code using the 0.6
API to 0.7.

## howl.command

See the [API docs](api/command.html).

Commands handlers now accept a single argument only. Some commands that accepted
multiple commands have been switched to accept a table with fields instead. For
instance:

```moonscript
-- 0.6 exec accepts two arguments
howl.command.exec '/tmp', 'ls'

-- 0.7 exec needs cmd and working_directory fields
howl.command.exec cmd: 'ls', working_directory: '/tmp'
```

---

## howl.interact

Behaviour of pre-defined interactions have changed. These are described below.
See the [API docs](api/interact.html).


### read_text

This should work the same.

```moonscript
-- works in both 0.6 and 0.7
howl.interact.read_text
  prompt: 'Name:'
  title: 'Enter your name'
```

### select

The `select` has fewer features. It does not accept `hide_until_tab`,
`allow_new_value` or the `on_change` callback. For using something like
`on_change` or `allow_new_value` you have to switch to the newer `explore`
interaction (see the [API](api/interact.html) and implement
it yourself. The call remains identical but returns different values. In 0.6
this returned a table with `selection` and `text` keys where text was the user
entered text. In 0.7 only the selection value is returned.

```moonscript
-- select call works in both 0.6 and 0.7, but returns different values
howl.interact.select
  prompt: 'Ice cream choice:'
  items: {'vanilla', 'chocolate'}

-- in 0.6 this returns
   {selection: 'vanilla', text: ''}
-- in 0.7 this returns
   'vanilla'
```

### select_location

The `select_location` interaction now allows `Chunk` locations in addition to
file and buffer locations. It does not support the `highlights` field, however
some newer field name provide the highlighting feature. An example is shown
below:

```moonscript
-- In 0.6, highlights may be specfied for buffer or file locations

buf = howl.app.editor.buffer
howl.interact.select_location
  items: {
    {'loc-1',
     buffer: buf,
     line_nr: 3,
     highlights: {{start_column: 1, end_column: 4}}},

    {'loc-2',
     buffer: buf,
     line_nr: 5,
     highlights: {{start_column: 6, end_column: 8}}},

    {'loc-3',
     file: howl.io.File('/tmp/x.txt'),
     line_nr: 10
     highlights: {{start_column: 4, end_column: 10}}}
  }

-- Code with identical behavior for 0.7 is shown below. Chunk locations may be
-- used in addition to buffer and file locations. The `highlights` field is not
-- used, instead you can specify the start_column and end_column directly.t2

buf = howl.app.editor.buffer
items = {
  {'loc-1',
    chunk: buf\chunk_for_span({start_column: 1, end_column: 4}, 3)},

  {'loc-2',
    buffer: buf,
    line_nr: 5,
    start_column: 6,
    end_column: 8},

  {'loc-3',
    file: howl.io.File('/tmp/x.txt')
    line_nr: 10
    start_column: 4
    end_column: 10}
}
```

### select_line

`select_line` is obsolete and not available. Two options can be used instead.
One is `select_location`  which now supports chunks (see above). The other
option is `buffer_search` which provides a quick search with preview option for
specified lines in a buffer. See the [API
docs](api/interact.html) for more info.

---

## The command line

Previously the command line API was available at `howl.app.window.command_line`.
This object is not available in 0.7. The replacement object is
`howl.app.window.command_panel`. This is an instance of the [CommandPanel]
object. The API has changed significantly and requires a rewrite. Some changes
are:

* This is no longer tightly coupled to the interactions. In fact CommandPanel is
not aware of interactions at all.
* Nested command line invocations use completely different command line objects.
Previously they shared the object and the object maintained a stack of running
activities. The new design greatly simplifies the model where each command line
object creates its own edit widget. There is no risk of one activitiy
accidentally stepping over another.
* There is still a `CommandLine` object but it is created internally by the
`CommandPanel` and passed to the *command line definition*.
* There is no concept of *. The redesign does not require this concept.
* There is no `add_help` method, instead there is a new [HelpContext] available
for use across Howl.

See the [CommandPanel] API from details.

[CommandPanel]: api/ui/command_panel.html
[HelpContext]: api/ui/help_context.html
