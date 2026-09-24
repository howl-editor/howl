---
title: howl.ui.CompletionPopup
---

# howl.ui.CompletionPopup

## Overview

A CompletionPopup is a [MenuPopup] showing completions for the word at the
cursor in an editor. Each [Editor] has one, as its `completion_popup` property,
which the editor shows when completing, either automatically as the user types
or on request.

The completions are provided by a [Completer], using the completers configured
for the buffer. The list is updated as the user types, and the popup closes when
the cursor leaves the word being completed or there are no more completions.
Choosing a completion inserts it using the completer.

There's normally no need to use a CompletionPopup directly: use the [Editor]'s
`complete` method to start a completion.

---

_See also_:

- The [MenuPopup] class which CompletionPopup is based upon
- The [Completer] spec, for how completions are provided
- The [spec](../../spec/ui/completion_popup_spec.html) for CompletionPopup

## Constructor

### CompletionPopup (editor)

Creates a new CompletionPopup for `editor`.

## Properties

### completer

The [Completer] for the current completion, if any.

### empty

Whether there are no completions.

### position

The start position of the word being completed, if completing.

## Methods

### complete ()

Starts completing at the cursor, unless the popup is already showing. The popup
is shown by the editor.

[Completer]: ../../spec/completer_spec.html
[Editor]: editor.html
[MenuPopup]: menu_popup.html
