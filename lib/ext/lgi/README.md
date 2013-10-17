# LGI

LGI is gobject-introspection based dynamic Lua binding to GObject
based libraries.  It allows using GObject-based libraries directly
from Lua.

Licensed under
[MIT-style](http://www.opensource.org/licenses/mit-license.php)
license, see LICENSE file for full text.

Home of the project is on [GitHub](http://github.com/pavouk/lgi).

LGI is tested and compatible with standard Lua 5.1, Lua 5.2 and
LuaJIT2.  Compatibility with other Lua implementations is not tested
yet.

If you need to support pre-gobject-introspection GTK (ancient GTK+ 2.x
releases), use [Lua-Gnome](http://sourceforge.net/projects/lua-gnome/).

## Installation:

In order to be able to compile native part of lgi,
gobject-introspection >= 0.10.8 development package must be installed,
although preferred version is >= 1.30.  The development package is
called `libgirepository1.0-dev` on debian-based systems (like Ubuntu)
and `gobject-introspection-devel` on RedHat-based systems (like Fedora).

Using LuaRocks:

    luarocks install lgi

Alternatively, use make-based installation:

    make
    [sudo] make install [PREFIX=<prefix>] [DESTDIR=<destdir>]

Please note that on BSD-systems you may need to use 'gmake'.

## Usage

See examples in samples/ directory.  Documentation is available in
doc/ directory in markdown format.  Process it with your favorite
Markdown processor if you want to read it in HTML.

## Credits

List of contributors, in no particular order:

- Uli Schlachter
- Jasper Lievisse Adriaanse
- Ildar Mulyukov
- Nils Nordman
- Ignas Anikevicius
- Craig Barnes
- Nicola Fontana
- Andreas Stührk

Many other people contributed to what lgi is today, in many forms -
writing patches, reporting bugs, packaging for distributions,
providing ideas, spreading a word...  *Many thanks to all of you!*

## History

### 0.7.2 (12-Sep-2013)

 - fix: improper marshalling of certain APIs passing pointers to
   records.
 - fix: cairo.PsSurface.create() had incorrect signature, missing
   filename.
 - fix: If GTK initialization fails, raise Lua exception instead of
   hard-crash of calling process.
 - fix: when running test in devel tree, prefer lgi from devel tree
   instead of the installed one.
 - add: cairo.Status.to_string() API
 - fix: avoid referencing GdkRGBA in GDk override when targetting
   Gdk2.0, which does not have GdkRGBA.
 - fix: replace GStaticRecMutex with GRecMutex to avoid compilation
   warnings.
 - fix: Gtk.Container.'child' pseudoproperty works even in Gtk2, where
   it was shadowed by internal field.
 - fix: add workaround for improperly parsed g_bytes_get_data()
   annotation.
 - fix: add workarounf for incorrect annotation on
   Pango.Layour.set_attributes(), which caused memory leak.
 - fix: adapt to Gio.InputStream.[read|read_all|read_async] API
   change, which does not accept buffer length argument any more (due
   to the newly added annotations).

### 0.7.1 (4-Mar-2013)

 - Add support for GStreamer 1.0, while still retaining GStreamer 0.10
   compatibility.
 - fix: crash when trying to to access '_class' attribute of class
   which does not have public classstruct exposed in typelib
 - fix: crash when passing 'nil' to transfer=full struct (caused crash
   of Awesome WM during startup).

### 0.7.0 (23-Feb-2013)

 - New feature - subclassing.  Allows creating GObject subclasses and
   implementing their virtual methods in Lua.
 - cairo: add support for most 1.12-specific cairo features
 - cairo: create hierarchy for Pattern subclasses
 - cairo: assorted small cairo bugfixes
 - samples: add GDBus client example
 - samples: add GnomeKeyring example
 - samples: GTK: offscreen window demos
 - samples: libsoup simple http server example
 - platforms: added support for darwin/macosx platform
 - platforms: additional fixes for OpenBSD
 - build: Makefiles now respect `CFLAGS` and `LDFLAGS` env vars values
 - build: Add Lua version option into Makefile
 - fix: custom ffi enum/flags handling
 - fix: more exotic callback-to-Lua marshalling scenarios
 - fix: do not allow GTK+ and gstreamer to call setlocale() - this
   might break Lua in some locales
 - fix: small adjustments, fixes and additions in Gtk override
 - fix: tons of other small fixes

### 0.6.2 (25-Jun-2012)
 - Avoid unexpected dependency on cairo-devel, cairo-runtime is now
   enough
 - Make `set_resident()` more robust and fix stack leak for Lua 5.2 case,
   avoid useless warning when `set_resident()` fails (to accomodate for
   static linking case).
 - Fix small memory leak (mutex) which occured once per opened
   `lua_State` using lgi.

### 0.6.1 (19-Jun-2012)
 - objects and structs: actually implement `_type` property as documented
 - tests: Fix regression tests for less common platforms
 - Pango: Add a few missing overrides
 - cairo: Fix `Context:user_to_device()` family of methods.
 - GStreamer: Add support for transfer!=none for input objects.  This
   is needed to avoid leaks caused by strange usage of transfer
   annotations of gstreamer-0.10
 - GStreamer: Add more missing overrides
 - GStreamer: Fix and improve samples
 - Various fixes for usecase when Lua context with loaded lgi is
   closed and opened again
 - Gtk: Add missing `Gtk.Builder:connect_signals()` override

### 0.6 (22-May-2012)
- Add cairo bindings, cairo sample and finish some gtk-demo parts
  which were requiring cairo

### 0.5.1 (not officially released)
- Fix a few problems on more exotic architectures (s390x, mips, ia64).
- Allow passing `byte.buffer` when UTF8 string is requested.

### 0.5 (15-Apr-2012)

- Port gtk3-demo to Lua code.  Try running 'lua samples/gtk-demo/main.lua'
- Finish override set for Gtk
- Extend and document features for interfacing LGI with external
  libraries (exporting and importing objects and structures via
  lightuserdata pointers).
- Fix: a few bugs with resolving bitflags values
- Fix: a few bugs in coroutines-as-callbacks feature
- Fix: workaround for crashing bug in gobject-introspection 1.32.0
- Fix: don't try to squeeze `GType` into `lua_Number` any more; this could
  cause crashes on some 64bit arches.

### 0.4 (4-Jan-2012)

- Changed handling of enums and bitflags, switched from marshaling
  them as numbers to prefering strings for enums and tables (sets or
  lists) for bitflags.  Numeric values still work for Lua->C
  marshalling, but backward compatibility is broken in C->Lua enum and
  bitflags marshalling.
- Compatible with Lua 5.2 and LuaJIT
- Added standardized way for overrides to handle constructor argument
  table array part.
- Existing Gtk overrides reworked and improved, there is now a way to
  describe and create widget hierarchies in Lua-friendly way.  See
  `docs/gtk.lua`, chapter about `Gtk.Container` for overview and
  samples.
- Various bugfixes and portability fixes.

### 0.3 (28-Nov-2011)

- Project hosting moved to GitHub.
- Build system switched from `waf` to simple Makefile-based one
- Added automatic locking of thread-sensitive libraries (Gdk and
  Clutter).  There is no need to add `Gdk.threads_enter()`,
  `Gdk.threads_leave()` and `Clutter.threads_enter()`,
  `Clutter.threads_leave()` pairs into application, lgi handles this
  automatically.
- Added new sample `samples/console.lua`, which implements already
  quite usable Lua console using Gtk widgets.
- Fixes for compatibility with older gobject-introspection 0.10.8
  package
- Testsuite is not built automatically, because building it can be
  apparently problematic on some systems, causing installation failure
  even when testsuite is not needed at all.
- Remove `setlocale()` initialization, which could break Lua when used
  with some regional locales.  The downside of this change is that
  marshaling file names containing non-ASCII characters on systems
  which define `G_BROKEN_FILENAMES` environment variable (probably
  only Fedora 15) does not work now.

### 0.2 (7-Nov-2011)

First public release
