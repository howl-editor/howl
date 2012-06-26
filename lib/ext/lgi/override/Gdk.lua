------------------------------------------------------------------------------
--
--  LGI Gdk3 override module.
--
--  Copyright (c) 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local select, type, pairs, unpack, rawget = select, type, pairs, unpack, rawget

local lgi = require 'lgi'
local core = require 'lgi.core'
local Gdk = lgi.Gdk
local cairo = lgi.cairo

-- Take over internal GDK synchronization lock.
core.registerlock(core.gi.Gdk.resolve.gdk_threads_set_lock_functions)
Gdk.threads_init()

-- Gdk.Rectangle does not exist at all, because it is aliased to
-- cairo.RectangleInt.  Make sure that we have it exists, because it
-- is very commonly used in API documentation.
Gdk.Rectangle = lgi.cairo.RectangleInt
Gdk.Rectangle._method = rawget(Gdk.Rectangle, '_method') or {}
Gdk.Rectangle._method.intersect = Gdk.rectangle_intersect
Gdk.Rectangle._method.union = Gdk.rectangle_union

-- Declare GdkAtoms which are #define'd in Gdk sources and not
-- introspected in gir.
local _ = Gdk.KEY_0
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
} do Gdk._constant[name] = Gdk.Atom(val) end

-- Better integrate Gdk cairo helpers.
Gdk.Window._method.cairo_create = Gdk.cairo_create
cairo.Region._method.create_from_surface = Gdk.cairo_region_create_from_surface

local cairo_set_source_rgba = cairo.Context._method.set_source_rgba
function cairo.Context._method:set_source_rgba(...)
   if select('#', ...) == 1 then
      return Gdk.cairo_set_source_rgba(self, ...)
   else
      return cairo_set_source_rgba(self, ...)
   end
end

local cairo_rectangle = cairo.Context._method.rectangle
function cairo.Context._method:rectangle(...)
   if select('#', ...) == 1 then
      return Gdk.cairo_rectangle(self, ...)
   else
      return cairo_rectangle(self, ...)
   end
end

for _, name in pairs { 'get_clip_rectangle', 'set_source_color',
		       'set_source_pixbuf', 'set_source_window',
		       'region' } do
   cairo.Context._method[name] = Gdk['cairo_' .. name]
end
for _, name in pairs { 'clip_rectangle', 'source_color', 'source_pixbuf',
		       'source_window' } do
   cairo.Context._attribute[name] = {
      get = cairo.Context._method['get_' .. name],
      set = cairo.Context._method['set_' .. name],
   }
end