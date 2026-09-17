---
title: About
---

# About Howl

Howl is a general purpose editor that aims to be both lightweight
and fully customizable. It is built on top of the very fast
[LuaJIT](http://luajit.org) runtime, uses [GTK](http://www.gtk.org) for its
interface, and can be extended in either [Lua](http://www.lua.org) or
[Moonscript](http://www.moonscript.org). It is known to work on Linux, but
should work on at least the \*BSD:s as well.

It is released as free software under the
[MIT](http://opensource.org/licenses/MIT) license, and is
available on [Github](https://github.com/howl-editor/howl).

## Overview

### General purpose

Howl is intended as a general purpose editor. As such it's not focused on any
particular language and has support for a multitude of languages and formats -
although the level of support for individual languages varies of course.

### Minimalistic, text oriented interface

While Howl uses GTK, its interface is primarily text oriented. Thus, it does
not offer any traditional dialogue boxes, tool bars, or even a menu bar. This is
not intended as dogma however. Future versions of Howl might offer optional
graphical elements such as the above should someone be willing to do the
necessary work.

Generally speaking, Howl draws a lot of inspiration from Emacs and Vim, and
should feel familiar to anyone who has used any of these editors.

### Features enabled by default

Some editors offer a very bare bones default install, leaving users with the
requirement to configure and add plugins to get the editing experience to a sane
default. While Howl is all about things being configurable, its policy is to
start off with basic features being enabled rather than disabled where it makes
sense.

### Customizable

Howl does not have an extension language. Instead, it is itself written almost
completely in Moonscript and Lua, using the same API's that's available for
everyone else. Its C core, discounting external dependencies, is miniscule (321
LOC at the time of this writing, comments and all.). Whether you're adding some
personal configuration code or writing a Howl bundle, you'll have access to the
API Howl itself is using.

Should the Howl API not be enough, you can directly interact with C libraries using
LuaJIT's [ffi](http://luajit.org/ext_ffi.html) library.

Howl can be developed for in either [Moonscript](http://www.moonscript.org) or
[Lua](http://www.lua.org), whatever suits your taste better. They both target
the Lua runtime, so whatever you choose you're going to have to learn Lua.
Fortunately, Lua is a small and quite elegant language that's easy to pick up if
you have any previous programming experience.

### Lightweight

Howl aims to be a light weight editor, with fast startup times and a small
footprint. This is one of the reasons for chosing LuaJIT as the runtime, which
among other things is known for its small size and fast startup. These things
are relative of course, but while it's nowhere near, say ed, you should find it
closer to Vim than to Emacs with respect to startup time and overall feel.

### In early stages

While Howl is stable and in active use, it's still in relatively early stages
of development, and as such there's lot of functionality that is still missing.
It might not do what you want, you might not get it to do what you want, or the
manual could have been better at helping you get it done. If so, feel free to
open a pull request, feature request, or issue at
[Github](https://github.com/howl-editor/howl), or better yet have a look at the
code or the manual and see if it's something you can fix yourself (and send a
pull request or patch).

## What's inside?

Howl is built on, embeds and uses a bunch of great software that deserves
to be mentioned:

#### [LuaJIT](http://luajit.org)

Quoted from the above page, LuaJIT is "a Just-In-Time Compiler (JIT) for the Lua
programming language". What Howl uses for its runtime. Very fast and lean, and
offers excellent C integration via its ffi interface.

#### [Moonscript](http://www.moonscript.org)

"MoonScript is a dynamic scripting language that compiles into Lua. It gives you
the power of one of the fastest scripting languages combined with a rich set of
features." Nearly all of Howl's code is written in Moonscript.

#### [LPeg](http://www.inf.puc-rio.br/~roberto/lpeg/)

Parsing Expression Grammars for Lua. Very powerful parsing stuff, but with a slight
learning curve. Used in Howl for lexers and other matching purposes.

#### [Scintillua](http://foicica.com/scintillua/)

"Scintillua adds dynamic Lua LPeg lexers to Scintilla.". While Howl does not strictly
speaking use Scintillua, it reuses a lot of its lexers.

#### [Busted](https://lunarmodules.github.io/busted/)

"Elegant Lua unit testing". Used in Howl for its specs.
