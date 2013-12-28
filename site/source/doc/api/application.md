---
title: Application
---

# Application

The Application object acts as the main hub within the Howl editor. There exists one and only one instantiated application object per Howl instance, available as `howl.app`.

## Properties

### .windows

A list of existing [Window](ui/window.html):s.

### .editors

A list of all existing [Editor](ui/editor.html):s. Each editor can be placed in only one window at a time, but this list holds all editors present for the current Howl instance - regardless of whether they're placed in the currently focused window or not.

### .buffers

A list of currently open [Buffer](buffer.html):s. The list is ordered by how recently a buffer was shown. Thus, a currently showing buffer will come before a buffer that is not shown, and  not showing buffers will be ordered according to the timestamp they were last shown.

### .next_buffer

This is the most recent buffer that is currently not showing in any editor. If all buffers are currently showing it's the first buffer in [.buffers](#.buffers).

## Methods

### new_window (properties = {})

Creates a new application [Window](ui/window.html). `properties` is table of window properties to set for the new window, such as title, height and width. The window is added to [.windows](#.windows) before the return of the method. Returns the newly created window.

### new_editor (options = {})

Creates a new [Editor](ui/editor.html). Unless `options` specify otherwise, the newly created editor is added to the currently focused window, to the right of the currently focused existing editor. It's set to show the buffer from the [.next_buffer](#.next_buffer) property. The editor is added to [.editors](#.editors) before the return of the method.

`options` can contain any of the following keys:

- *buffer*: The buffer that should be shown in the editor. Defaults to [.next_buffer](#.next_buffer).
- *window*: The window to add the editor to. Defaults to the currently focused window.
- *placement*: How the new editor should be placed in the target window. See [Window.add_view](ui/window.html#add_view) for more information about possible placement values.

#### Example use (Moonscript):

```moon
buffer = howl.app\new_buffer!
buffer.text = 'Show this text in the new buffer'
howl.app\new_editor :buffer
```

### new_buffer (buffer_mode = nil)

Creates a new buffer, and adds it to [.buffers](#.buffers). `buffer_mode` can optionally be specified to assign a specific mode for the new buffer directly. When not specified, the [default mode](modes/default_mode.html) is used. See [mode](mode.html) for more information about buffer modes.
