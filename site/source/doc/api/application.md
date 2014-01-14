---
title: howl.Application
---

# Application

The Application object acts as the main hub within the Howl editor. There exists one and only one instantiated application object per Howl instance, available as `howl.app`.

## Properties

### .windows

A list of existing [Window]:s.

### .editors

A list of all existing [Editor]:s. Each editor can be placed in only one window at a time, but this list holds all editors present for the current Howl instance - regardless of whether they're placed in the currently focused window or not.

### .buffers

A list of currently open [Buffer]:s. The list is ordered by how recently a buffer was shown. Thus, a currently showing buffer will come before a buffer that is not shown, and  not showing buffers will be ordered according to the timestamp they were last shown.

### .next_buffer

This is the most recent buffer that is currently not showing in any editor. If all buffers are currently showing it's the first buffer in [.buffers].

## Methods

### new_window (properties = {})

Creates a new application [Window]. `properties` is table of window properties to set for the new window, such as title, height and width. The window is added to [.windows] before the return of the method. Returns the newly created window.

### new_editor (options = {})

Creates a new [Editor]. Unless `options` specify otherwise, the newly created editor is added to the currently focused window, to the right of the currently focused existing editor. It's set to show the buffer from the [.next_buffer] property. The editor is added to [.editors] before the return of the method.

`options` can contain any of the following keys:

- *buffer*: The buffer that should be shown in the editor. Defaults to [.next_buffer].
- *window*: The window to add the editor to. Defaults to the currently focused window.
- *placement*: How the new editor should be placed in the target window. See [Window.add_view](ui/window.html#add_view) for more information about possible placement values.

#### Example use (Moonscript):

```moon
buffer = howl.app\new_buffer!
buffer.text = 'Show this text in the new buffer'
howl.app\new_editor :buffer
```

### new_buffer (buffer_mode = nil)

Creates a new buffer, and adds it to [.buffers]. `buffer_mode` can optionally be specified to assign a specific mode for the new buffer directly. When not specified, the [default mode] is used. See [mode] for more information about buffer modes.

### add_buffer (buffer, show = true)

Adds the existing `buffer` to [.buffers]. If `show` is true, shows the buffer in
the currently active editor.

### close_buffer (buffer, force = false)

Removes `buffer` from [.buffers]. If the buffer is modified, and `force` is not
true, the user  is prompted before closing the buffer.

### open_file (file, editor = _G.editor)

Opens the provided [file](fs/file.html). By default, unless `editor` specifies a
specific editor to open the file into, the file is opened in the currently
active editor. Emits the `file-opened` signal if the file was opened
successfully.

### save_all ()

Saves all modified buffers in one go.

### synchronize ()

Synchronizes all open files with their respective files, if any. This will cause
any non-modified buffers to be reloaded from disk, should the file be more
recently modified than the buffer.

### quit ()

Requests for Howl to quit. Should any modified buffers be open, this will cause
the user to be prompted for verification before actually quitting.

### save_session ()

Saves the current editing session to disk. This includes things such as
information about what buffers are open, the current state of the window, etc.

[.buffers]: #.buffers
[.editors]: #.editors
[.next_buffer]: #.next_buffer
[.windows]: #.windows
[Buffer]: buffer.html
[Editor]: ui/editor.html
[Window]: ui/window.html
[mode]: mode.html
[default mode]: modes/default_mode.html
