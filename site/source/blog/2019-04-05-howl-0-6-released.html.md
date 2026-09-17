---
title: Howl 0.6 released!
location: Stockholm, Sweden
---

We are very happy to announce the release of [Howl](http://howl.io/) 0.6,
available for download [here](/getit.html)!

It's been some time since the last release, but good things come to those who
wait :) Highlights of this release are mentioned below and the full changelog
since 0.5 is included at the bottom of this blog post. Thanks to all of our
contributors!

READMORE

### File search support

One of the major new features in Howl 0.6 is the support for quickly and easily
searching files within the current project. This new feature is supported by two
new commands, the `project-file-search` command (bound to `ctrl_shift_f` by
default) and the `project-file-search-list` command (bound to `ctrl_shift_g` by
default). These two commands serves multiple use cases that should make editing
and coding easier.

The `project-file-search` command is great for quickly navigating around in your
code base, or to easily preview different usages or occurences. Just press
`ctrl_shift_f` on the current word and you'll see a list of all matching
occurences, allowing you to both see all usages and navigate to the location of
your choice. As you'd expect from Howl in general you'll get live previews for
all matches in the list (and syntax highlighted matches at that):

![project-file-search](/images/screenshots/monokai/project-file-search.png)

You can preview the matches by moving up and down in the list, and choose to
navigate to a specific location by pressing `enter`.

There's also the new `project-file-search-list` command. While the previous
`project-file-search` command is great for quick navigation and previewing,
another use case (especially when coding) is to process all occurences of a
particular hit. As an example, you might want to refactor a particular function
and need to update or verify all usages of it. In this scenario
`project-file-search-list` is your friend. Instead of presenting all hits in a
popup list for navigation, this command will instead show all the matches in a
buffer, allowing you go through and check off each match.

![project-file-search-list](/images/screenshots/monokai/project-file-search-list.png)

You can navigate the buffer as you would do a normal buffer, and you can
navigate to a specific occurence by pressing `enter`. Any visited items are
marked visually in order to help you keep track of what items you have
processed. You can also manually mark results as processed or not processed by
pressing `space` on a specific occurence. You can turn on automatic previews for
the search results by pressing `p`, and turn them off using `escape`.

Under the hood searching is accomplished by utilizing a particular "searcher".
Howl ships with built-in support for the [Ripgrep
(rg)](https://github.com/BurntSushi/ripgrep) searcher and the [silver searcher
(ag)](https://geoff.greer.fm/ag/), and also provides a native Howl searcher in
case neither of those are present. You can of course also provide your own
searcher if you like by registering one with the
[file_search](/doc/api/file_search.html) module.

_See also: the [docs](/doc/manual/files.html#searching-files) for file
searching._

### Navigation support

Together with the new file search comes the support for general buffer
navigation. Particularly when coding a lot of time is spent navigating back and
forth between various files, or between different locations in the same file.

To help with that the 0.6 release ships with three new commands:

- `navigate-back`, bound to `ctrl_<` by default
- `navigate-forward`, (bound to `ctrl_>` by default
- `navigate-go-to`, bound to `alt_<` by default

The `navigate-back` and `navigate-forward` commands allows you to go back and
forth to previous locations of interest, while the `navigate-go-to` command will
present you with a list of previous locations that you can choose from. While
it's easy to see how useful this is coupled with the new file search
functionality, navigation support is useful even when not performing file
searches. There are a lot of other ways for navigating files, such as ordinary
searces, buffer structure navigation, etc. where it's useful to be able to
quickly go back and forth, so make sure you get into the habit of using the new
feature!

_See also: the [docs](/doc/manual/files.html#navigating-buffers) for navigating
buffers._

### File selector performance improvements

There has been some work spent since the last release on improving the
performance of the file selector, as well as improving the user experience for
potentially long-running operations. This was documented in a previous blog
post, ["File selection
improvements"](/blog/2017/12/15/file-selection-performance.html), so while we
won't reiterate that here and encourage you to read the blog post instead know
that with 0.6 opening files is faster then ever :)

### A new theme

0.6 ships with a new built-in theme, [Dracula](/screenshots/dracula.html):

![dracula](/images/screenshots/dracula/project-file-search-list.png)

Click on the link above to see it in its full glory, and if you're interested in
more then please also have a look at the additional themes listed in the
[Howl wiki](https://github.com/howl-editor/howl/wiki/Howl-Bundles#themes).

### The journal buffer

Did you ever wonder if you missed a status update in the status bar, or wondered
about one you saw earlier? Then the new journal buffer comes to the rescue!
Simply run the `open-journal` command in the command line to see earlier log
messages .

### In closing

As ever, there are a lots of changes that haven't been mentioned here, so have a
look at the changelog since 0.5 below for more information (which is probably
not complete either). We'll aim for doing more timely releases in the future,
but we also like to remind every one that the master branch is intended to be
stable at all times, so if you want to get the latest developments as they
happen then you shouldn't be afraid to jump on the train.

Code with the pack!

## Full Changelog since 0.5

- Added `navigate-go-to` command, for going back to a specific previous
location.

- Added support for a "journal" buffer showing the Howl log, available via
`open-journal`.

- Ensure loaded buffers contain valid UTF-8 at all times

- C: Support for lexing raw strings

- Rust: Improved lexing

- Added support for specifying line and column when opening files, e.g.

```shell
$ howl my-file:10

$ howl my-file:10:2
```

Works both when opening a file locally or remotely using `--reuse`.

- Added support for custom user fonts (place them in <CONFIG-DIR>/fonts, e.g.
~/.howl/fonts)

- Added `project-switch-buffer` command that displays open buffers within
the current project.

- Added two inspectors and a command for documentation to the Go mode

- Moving cursor left or right with a selection active now cancels the selection,
leaving the cursor at the corresponding end.

- Added proper structure support for C/C++ mode

- Base scheme support on the newer lisp mode instead of old basic mode

- Added the `**popup_menu_accept_key` option, for controlling which key accepts
the current option for a popup menu, such as the completion popup. Valid values
are 'enter' (the default) or 'tab'.

- Close completion popup when user activity warrants it (e.g. direction keys,
clicking in another location using the mouse, etc.)

- Added new built-in theme: Dracula

- Added integrated and fast project file search functionality via two new
commands: `project-file-search` and `project-file-search-list`

- Javascript: Support for ES6 templates and new keywords and operators

- Performance and functionality improvements for the matcher, used in Howl
selection lists, enabling fast matching across much larger data sets.

- Performance improvements for recursive file selections (`project-open` and
ordinary recursive `open` command): Between 30x and 32x faster.

- Respect use_tabs option when commenting

- Ensure scrolling works correctly for Gtk+ 3.4

- Dart bundle enhancements: improved syntax highlighting

- Added support for activities - potentially longer running activities that
should run in a apparently blocking way to the user. Example: Loading files from
larger directories will now be run as a user visible and user cancellable
operation if it takes to long to complete.

- Added a new commandline flag, `--run-async`, for running a particular file in
a asynchronous Howl context.

- Added support for shared, low precision after timers

- Added options for controlling scrolling speed

- Add support for smooth scrolling events (needed for Wayland with two-finger
scrolling)

- Fixed background drawing for Wayland/Weston/CSD environments (borders outside
of the window).

- Requested that titlebar is hidden for newer versions of Gnome 3.

- Added support for navigating back and forth in a list of previously visited
locations. Two new commands, `navigate-back` and `navigate-forward` were added,
bound to `ctrl_<` and `ctrl_>` respectively.

- Improved key translation for keys when caps lock is on.

- Better Python lexing

- Added two new commands, `editor-newline-above` and `editor-newline-below`,
that insert a new line above/below the current line. Bound these commands to
`ctrl_shift_return` and `ctrl_return`.

- Auto detect line endings when opening a file if possible

### Issues resolved

- Issues as seen on
[Github](https://github.com/howl-editor/howl/issues?utf8=%E2%9C%93&q=closed%3A2016-06-06..2019-04-05+is%3Aissue+is%3Aclosedsort%3Acreated-desc)
