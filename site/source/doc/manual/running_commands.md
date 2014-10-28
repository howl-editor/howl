---
title: Running external commands
---

# Running external commands

## Overview

While most of the time spent developing is likely to be editing, there's often a
need for running external commands as part of the work flow. You might for
instance want start of a compilation, run some tests, or launch other processes
related to what you're doing at the moment. Howl provides two different commands
for this purpose, `exec` and `project-exec`, bound to `ctrl_shift_r` and
`ctrl_alt_r` respectively. They both work the same way, allowing you execute a
command of your choice from within a directory, and displaying any output in a
buffer. The difference is that `project-exec` starts out from from the root of
your current project directory, while `exec` starts out in the directory
associated with the current buffer.

## Interacting with the prompt

![Exec prompt](/images/doc/exec-prompt.png)

Upon executing one of the above commands, you'll end up in the prompt. The
prompt offers specific completions and ways of making it easier to input your
command. Just as with the ordinary prompt for opening a file, you can enter
`backspace` to move up one directory level. Entering `~` and `/` allows you to
quickly run a command from your home directory or the root directory,
respectively. Completions are available both for commands themselves as well as
arguments, and support completion of arguments spanning multiple directory
levels (e.g. `./my-dir/sub-dir/foo`).

As a final convenience, the prompt supports an internal `cd` command, allowing
you to move to a different directory within the prompt.

## Running commands

Having chosen your command of choice, the specified command will be run as you
press `enter`. Both the `exec` and `project-exec` commands will launch the
specified command in the directory displayed in the prompt, using your shell.
The fact that your shell is used for this allows for the use of any ordinary
shell aliases you normally use (provided that they are available for non-login
shells) as well as shell constructs such as for loops, etc.

The command thus launched will be associated with a new buffer, in which any
output from the command will be displayed. Commands will not block the editor
while running, so you're free to resume your other tasks while the the command
runs. There is also no limitation on the number of concurrently executing
commands you might have - they will all be associated with their own buffers
that you can switch between as you please, as illustrated by the below image.

![Concurrent commands](/images/doc/concurrent-commands.png)

Also illustrated by the above image is the fact that Howl adds some extra
support for displaying a command's output. For an ordinary command any standard
output will be displayed plainly, while error output will be shown in a
different style to allow you to quickly differentiate between the two. In
addition to this Howl also supports ANSI color escape codes should the output
contain these.

## Dealing with rogue commands

While a well behaved command will exit on its own, occasionally there are those
that need an helping hand. Pressing `Ctrl + c` when in a process buffer will
send the `SIGINT` signal to the currently running process, hopefully hastening
its way towards a graceful exit (`Ctrl + c` while a selection is active will still
only copy the selection). For the obstinate cases, `Ctrl + backslash` can be
used to send the `SIGKILL` signal.






---

*Next*: [What's next?](next.html)
