# The Howl editor

[![Build Status](https://github.com/howl-editor/howl/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/howl-editor/howl/actions/workflows/ci.yml)

## NOTE

The master branch is now an unreleased version, built on Gtk-4. It has not been
through a release, and the documentation at [howl.io](http://howl.io) still
describes 0.6.

If you want the last released version, check out the `0.6` tag:

    git checkout 0.6

The last state of master before the Gtk-4 work landed is commit `0ca4ffa2`, if
you need something more recent than 0.6 but still on Gtk-3.

## What is it?

Howl is a general purpose editor that aims to be both lightweight
and fully customizable. It's built on top of the very fast
[LuaJIT](http://luajit.org) runtime, uses [Gtk](http://www.gtk.org) for its
interface, and can be extended in either [Lua](http://www.lua.org) or
[Moonscript](http://www.moonscript.org). It's known to work on Linux, but
should work on at least the \*BSD's as well.

It is released as free software under the [MIT](http://opensource.org/licenses/MIT)
license, with the source being available on [Github](https://github.com/howl-editor/howl).

Visit [howl.io](http://howl.io) for installation instructions and documentation,
and follow on [Twitter](https://twitter.com/howleditor) for updates.

## Quick installation instructions

The home page contains more elaborate instructions, including pointers to
existing distribution packages, but below you'll find the basic instructions for
how to install Howl from source.

### Build requirements

- `wget`: For auto-downloading build dependencies.
- `GTK+`: Version >= 4, with development files (e.g. `libgtk-4-dev` on Debian
based system).
- `C compiler`: Howl has a very small C core itself, and it embeds
dependencies written in C.
- `pkg-config`: Helper tool to find libraries on the system.

### Build && install

Clone the repository or download and unpack a release. Cd into the `src`
directory, and run `make && sudo make install`. The installed binary will be
named `howl`.

## License

Howl is released under the MIT license (see the LICENSE.md file for the full
details).

## Contribute

Howl is a spare-time project, and I'm not actively looking for contributions.

The [issue tracker](https://github.com/howl-editor/howl/issues) and pull
requests remain open on GitHub, so feel free to use them. Please do so knowing
that I make no promises about responding to, reviewing or merging anything, and
that issues and pull requests may sit untouched indefinitely.

GitHub is the only channel. Please don't send patches or bug reports by any
other means.
