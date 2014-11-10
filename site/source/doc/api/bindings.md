---
title: howl.bindings
---

# howl.bindings

## Overview

howl.bindings handles the set of active key bindings within Howl. "Bindings" in
this context refers to the various actions that will be executed as the result of
a key press, and we say that a key is bound to a certain action whenever that action
will trigger as a result of the key being pressed.

The way this works in Howl is that bindings keeps track of an arbitrary number
of "keymaps" that are searched whenever a key is pressed. A keymap is simple a
Lua table with keys matching key translations. The keymaps are stacked, and they
will all be searched for a matching action whenever a key is pressed. Typically
processing stops whenever the first action has been triggered, but it's possible
for a handler to allow a key press to propagate further down the stack if it so
chooses.

Keymaps are as said simple Lua tables, that maps "key translations" to actions.
Each key press is represented as a "key event", which is also a simple Lua table.
Below you can see an example of a key event resulting from pressing
`Control + Shift + a`:

```lua
-- Key event
{
  character = "A", -- the character corresponding to the key press, if any
  key_code = 65,   -- the code of the key pressed
  key_name = "a",  -- a symbolic name for the key pressed, if any
  alt = false,     -- true if the alt key was held down during the key press
  control = true,  -- true if the control key was held down during the key press
  meta = false,    -- true if the meta key was held down during the key press
  shift = true,    -- true if the shift key was held down during the key press
  super = false    -- true if the super key was held down during the key press
}
```

As part of [processing](#process) the key event is translated to a list of
possible string representations using [translate_key](#translate_key), which
for the above example would result in the following list of translations:

```lua
{
  "ctrl_A",
  "ctrl_shift_a",
  "ctrl_shift_65"
}
```

All keymaps are then searched in order for keys matching any of the translations.
If you read the documentation for [process](#process) you'll see that all key
events are processed for a particular originating source. In the typical case
this will be "editor", indicating the key press originated from an
[editor](ui/editor.html). When searching keymaps, any keymap is first inspected
to see if it has a source specific keymap table, in which case this is searched
first before any top-level bindings. Consider the following keymap:

```lua
{
  ctrl_b = function() print("A general binding") end,
  ctrl_c = 'my_general_command',

  editor = {
    ctrl_shift_a = function(editor) print("An editor binding") end
  }
}
```

Should the key event example above be dispatched against this keymap with the
source being "editor", it would trigger the "ctrl_shift_a" binding. The top-level
bindings (e.g. "ctrl_b") would trigger regardless of source. Also note that
the editor specific binding can make use of a source specific extra argument,
an editor instance in this case.

Any matching value found in a keymap is considered an action. Should a keymap not have any
matching keys but have a callable field named `on_unhandled`, that is
invoked with the key event, event source, key translations and any extra parameters
passed to [dispatch](#dispatch), and any truthy result is used as the action.
See the documentation for dispatch for further information about these parameters.

Actions can be one of three different things:

- It can be a string, in which case it's considered a command and will be dispatched
using [command.run](command.html#run).

- It can be a callable object (a function or table providing a meta-table __call), in
which case it's invoked with any extra parameters passed to [dispatch](#dispatch)
(the typical case being the editor instance for which the key press originated).
The key event will be considered handled unless the handler returns false.

- It can be an ordinary, non-callable, table. This table is interpreted as an additional
keymap, which will be [pushed](#push) using the `pop` option.

### Indirect bindings

When writing keymaps for non-editor sources, a special key called `binding_for`
can be used in the keymap to bind an action to a key press indirectly by using a
command name as the key. For example, if you wanted to support *pasting* in your
readline input, instead of binding the action directly to the `ctrl_v` key
press, you might want to bind whichever key is bound to the `editor-paste`
command. This can be specified by the following keymap:

```lua
{
  binding_for = {
    ['editor-paste']: function() ... end
  }
}
```

This ensures that if the user binds a new key press to the `editor-paste`
command, that new key press will now trigger the bound action above, providing a
better experience for the user.

*Protip*:

You can use the `describe-key` command to interactively view information for any
particular key press, i.e. the key event and translations.

_See also_:

- The [spec](../spec/bindings_spec.html) for howl.bindings

## Properties

### .is_capturing

True if there's currently a capture handler installed, and false otherwise.

### .keymaps

This is a list of the currently active keymaps. This is a stack, with latter keymaps taking precedence over earlier ones.

## Functions

### action_for (translation)

Searches the stack of kemaps for the given key translation and returns the first
bound action found. An action may be a string (i.e. a command name) or a
function object. If no binding can be found for the translation, `nil` is
returned.

### binding_for (action, source)

Finds the first key binding that is bound to the specified `action`. `source`,
if given, specifies the source specified keymaps to search. Returns the binding,
or `nil` if no binding was found.

For example:

```lua
-- look up the binding for the `project-open` command:
howl.bindings.binding_for('project-open')
-- => 'ctrl_p'

-- look up the binding for the `buffer-search-forward` command:
howl.bindings.binding_for('buffer-search-forward', 'editor')
-- => 'ctrl_f'

-- but since that's a command only bound for editor sources,
-- it's not bound globally
howl.bindings.binding_for('buffer-search-forward')
-- => nil
```

### cancel_capture ()

Removes any installed capture handler.

### capture (handler)

Installs a capture handler. The handler, which should be callable, will
intercept any key events being sent to [process](#process) for processing. It
will be invoked with the key event, source, key translations and any extra
parameters passed to process. Unless the handler returns `false`, it will
automatically be removed after the invocation. There can be only one capture
handler installed at any given time. Installing a capture handler when an
existing one is already set will simply override the previous one.

### dispatch (key_event, source, keymaps, ...)

Explicitly dispatches the key event against the specified list of keymaps.
`source` is the source of the key press, e.g. "editor". `keymaps` is the
list of keymaps that will be searched. Any additional arguments are passed
as is to any callable actions.

*Note*:

Unlike [process](#process), dispatch will not automatically include any of the
keymaps in the binding stack, it will only search `keymaps`.

### pop ()

Pops the top-most keymap of the stack. Raises an error if the stack is empty.

### process (key_event, source, extra_keymaps = {},  ...)

Processes the `key_event` by dispatching it against the list of keymaps present
in the bindings stack. `source` is the source of the key press, e.g. "editor".
`extra_keymaps` is an optional list of additional keymaps that will be searched;
if specified these will be searched in order before any of the keymaps in the
stack. Any additional arguments are passed as is to any callable
actions.

Should any capture handler be installed via [capture](#capture), this will be
invoked first and further processing will be skipped.

The `key-press` signal is emitted before dispatching, and further processing
will be skipped if this is handled.

### push (keymap, options = {})

Pushes `keymap` onto the bindings stack. `options` can contain any of the following keys:

- *block*: When set to true, this prevents any keymaps lower in the stack to be searched for
  matching actions, effectively making this the only keymap available.

- *pop*: When set to true, this causes the keymap to be popped from the stack automatically
  after the next key dispatch. If pop is set, the map is implicitly blocking as
well.

### remove (keymap)

Removes the specified keymap from the stack. Returns true if the keymap was removed successfully and false if it was not found.

### translate_key (event)

Returns a list of translations for the passed in key event.

Example (Lua):

```lua
-- Given the following key event
local key_event = {
  alt = false,
  character = "A",
  control = true,
  key_code = 65,
  key_name = "a",
  meta = false,
  shift = true,
  super = false
}

bindings.translate_key(key_event)
-- returns
{
  "ctrl_A",
  "ctrl_shift_a",
  "ctrl_shift_65"
}
```
