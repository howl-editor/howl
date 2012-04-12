------------------------------------------------------------------------------
--
--  LGI Gdk3 override module.
--
--  Copyright (c) 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local select, type, pairs, unpack = select, type, pairs, unpack
local lgi = require 'lgi'
local core = require 'lgi.core'
local Gdk = lgi.Gdk

-- Take over internal GDK synchronization lock.
core.registerlock('Gdk', 'gdk_threads_set_lock_functions')

-- Gdk.Rectangle does not exist at all, beacuse it is aliased to
-- cairo.RectangleInt.  Make sure that we have it exists, because it
-- is very commonly used in API documentation.
Gdk.Rectangle = lgi.cairo.RectangleInt

-- Declare GdkAtoms which are #define'd in Gdk sources and not
-- introspected in gir.
for name, val in pairs {
   SELECTION_PRIMARY = 1,
   SELECTION_SECONDARY = 2,
   SELECTION_CLIPBOARD = 69,
   TARGET_BITMAP = 5,
   TARGET_COLORMAP = 7,
   TARGET_DRAWABLE = 17,
   TARGET_PIXMAP = 20,
   TARGET_STRING = 31,
   SELECTION_TYPE_ATOM = 4,
   SELECTION_TYPE_BITMAP = 5,
   SELECTION_TYPE_COLORMAP = 7,
   SELECTION_TYPE_DRAWABLE = 17,
   SELECTION_TYPE_INTEGER = 19,
   SELECTION_TYPE_PIXMAP = 20,
   SELECTION_TYPE_WINDOW = 33,
   SELECTION_TYPE_STRING = 31,
} do Gdk[name] = core.record.new(core.gi.Gdk.Atom, val) end

-- Make sure that Gdk is initialized with threads.
Gdk.threads_init()
