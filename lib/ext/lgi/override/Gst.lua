------------------------------------------------------------------------------
--
--  LGI Gst override module.
--
--  Copyright (c) 2010, 2011, 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local ipairs = ipairs
local os = require 'os'

local lgi = require 'lgi'
local gi = require('lgi.core').gi
local GLib = lgi.GLib
local Gst = lgi.Gst

-- GstObject has special ref_sink mechanism, make sure that lgi core
-- is aware of it, otherwise refcounting is screwed.
Gst.Object._refsink = gi.Gst.Object.methods.ref_sink

-- Gst.Element; GstElement uses ugly macro accessors instead of proper
-- GObject properties, so add attributes for assorted Gst.Element
-- properties.
Gst.Element._attribute = {}
for _, name in ipairs {
   'name', 'parent', 'bus', 'clock', 'base_time', 'start_time',
   'factory', 'index', 'state' } do
   Gst.Element._attribute[name] = {
      get = Gst.Element['get_' .. name],
      set = Gst.Element['set_' .. name],
   }
end

function Gst.Element._method:link_many(...)
   local target = self
   for _, source in ipairs {...} do
      if not target:link(source) then
	 return false
      end
      target = source
   end
   return true
end

-- Gst.Bin adjustments
function Gst.Bus._method:add_watch(callback)
   return self:add_watch_full(GLib.PRIORITY_DEFAULT, callback)
end

function Gst.Bin._method:add_many(...)
   local args = {...}
   for i = 1, #args do self:add(args[i]) end
end

-- Gst.TagList adjustments
if not Gst.TagList.copy_value then
   Gst.TagList._method.copy_value = Gst.tag_list_copy_value
end
function Gst.TagList:get(tag)
   local gvalue = self:copy_value(tag)
   return gvalue and gvalue.value
end

-- Load additional Gst modules.
local GstInterfaces = lgi.require('GstInterfaces', Gst._version)

-- Initialize gstreamer.
Gst.init()

-- Undo unfortunate gstreamer's setlocale(LC_ALL, ""), which breaks
-- Lua's tonumber() implementation for some locales (e.g. pl_PL, pt_BR
-- and probably many others).
os.setlocale ('C', 'numeric')
