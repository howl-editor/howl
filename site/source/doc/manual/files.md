---
title: Working with files
---

# Working with files

## Opening files

Howl provides a text-oriented interface, and so you want see any traditional
graphical open file dialogs. Instead you'll open files from the command line,
using commands. First off, the `open` command lets you navigate the file system
and select a file to open. It's bound to `ctrl_o` in the default keymap, and is
also aliased as `e` for those more comfortable with VI. Triggering that command
opens up the command line prompt and displays the contents of the current
directory, as determined by the current buffer:

![File open](/images/doc/file-open.png)

Once you're in the prompt, you  can then select the file of your choice. You can
choose the file from the list by manually navigating using the arrow keys,
`ctrl_p`, `ctrl_n`, etc., if you want. However, it's usually much faster to
narrow down the list by typing something that matches the file you want. Just as
with completions (as described in the [previous](completions.html) section),
your input string will be matched against the available files using boundary
matching or exact matching. Once the selected file ends up at top, simply press
enter to open it.

If the file you selected is a directory, the list and prompt will update itself
for the selected directory, letting you pick a file there. On the other hand, if
you want to go up a directory level, press `backspace`. For convenience, if you
type `~/` or `/` at the start of a prompt, you will be directly transferred to
your home directory and the root directory respectively.

### Opening a file within a project

Navigating the file system and selecting a file for opening is all fine and good
for the odd file you want to open. Most of the time however, you're likely
working within the context of a project of some sort. In that case it can
quickly get tedious to navigate directories up and down, and especially for
larger projects, since you might not even be entirely sure where a desired file
is placed. Fortunately, Howl offers the `project-open` command to help with
this.

Howl provides simple and light-weight support for projects. In Howl, a project
is currently defined as root directory containing the project files below, with
an optional version control system attached to it. The `project-open` command
(bound to `ctrl_p` by default) provides a way of selecting a file to open from
all the files contained in your project. Thanks to the matching capabilities,
this often provides a much faster way of opening files than navigating the
project directory structure do. Below you'll see an example for the Howl project
itself:

![Project open](/images/doc/project-open.png)

## Opening a file within a subtree

When viewing the file listing for a directory within the `open` command, you can
press `ctrl_s` to instantly switch to a 'subtree' view. This shows all files
within the directory tree rooted at the current directory allowing you to
quickly find a file within that subtree. This is somewhat similar to
`project-open`, however it can be activated in any directory. To switch back to
the regular, single level view, press `ctrl_s` again.

## Saving buffers

Invoke the `save` command to save the current buffer to a file. If the buffer
has an associated file, it will get saved to that file, and otherwise you'll be
prompted for the file name to save the buffer to. The `save` command is bound to
`ctrl_s` in the default keymap, and is also aliased as `w`.

To save a buffer with an associated file to another file, invoke the `save-as`
command (bound to `ctrl_shift_s` in the default keymap). There's also a related
command, `save-and-quit`, that allows you to save any modified buffers and exit
Howl in one go.

## Switching between open buffers

While Howl provides the ability to view more than one buffer at a time by
supporting multiple open views, you'll likely have more buffers open than you
can fit on your screen. In order to switch to another buffer, you can use the
`switch-buffer` command (bound to `ctrl_b` by default):

![switch-buffer](/images/doc/switch-buffer.png)

This let's you select an open buffer to display in the current view. The list as
presented is ordered by access time, thus you'll see your most recent buffers at
the top with less recently used buffers below. As always, you can type to narrow
down the list.

Another command that might prove useful to you is
`switch-to-last-hidden-buffer`. This will switch to the most recently accessed
buffer that is not currently showing in any view, and is thus useful for quickly
switching between to related files in the same view.

## Creating new buffers / files

So what do you do if you just want to create a new buffer, that will eventually
get saved to a new file? Well, there is a `new-buffer` command available for
this, which will create a new buffer without an associated file, that you can
later save to a named file. This is not bound to any key by default however, and
the reason for that is that it's not considered that useful. Most of the time
when you want to create a new file, you already know what the file should be
named. And as is the case with some other editors, such as Emacs or Vim, it is
not a requirement for a file to actually exists in order to successfully open
it. Thus, if you want to create a new file whose name you already know, just
open the file using the `open` command and enter the new name of the file.

If this sounds strange to you, consider that a buffer and a file are two
different entities, and that a buffer only has an association with a file. So
when you open a non-existing file, you create a new buffer with an association
to the specified file, which does not have to exist. As you save the buffer, the
file will be created as necessary.

*Next*: [Editing](editing.html)

