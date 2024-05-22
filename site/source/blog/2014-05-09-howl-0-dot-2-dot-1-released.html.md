---
title: Howl 0.2.1 Released
location: Stockholm, Sweden
---

![howl-0.2.1](blog/0-2-released/howl-02.png)

Howl 0.2.1 has been released. This is a patch release for the previous [0.2
release](/blog/2014/04/30/howl-0-dot-2-released.html) of Howl. As such, it only
contains a small amount of changes relative to 0.2, listed below. The release is
available for download [here](/getit.html).

READMORE

## Full Changelog since 0.2

### New and improved

- Added a new command `editor-cycle-case` that changes the case of the current
word or selection. The new case is automatically chosen based on the current
case. The command cycles through lowercase -> uppercase -> titlecase.

- Prompt before saving a buffer if the file on disk was modified (issue #25)

### Bugs fixed

- Moonscript: Fix incorrect lexing of `nil`, `true`, and `false` when they are
prefixes of an identifier.

- Haml: Properly lex attribute lists after class and id declarations

- `editor-paste` now cuts any existing selection before pasting (issue #26)

- Cairo error introduced with patch for flickering on Gtk 3 in 0.2, that was
seen on Gtk 3.4.2 (issue #28)

- Sporadic and rare LuaJIT "bad callback" panic should be fixed.
