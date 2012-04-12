# LGI

LGI is gobject-introspection based dynamic Lua binding to GObject
based libraries.  It allows using GObject-based libraries directly
from Lua.

Licensed under
[MIT-style](http://www.opensource.org/licenses/mit-license.php)
license, see LICENSE file for full text.

Home of the project is on [GitHub](http://github.com/pavouk/lgi).

LGI is tested and compatible with standard Lua 5.1 and Lua 5.2 and
recent LuaJIT 2 betas.  Compatibility with other Lua implementations
is not tested yet.

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
markdown processor if you want to read it in HTML.

## History

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
