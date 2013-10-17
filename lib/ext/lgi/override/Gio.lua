------------------------------------------------------------------------------
--
--  LGI Gio2 override module.
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local select, type, pairs = select, type, pairs
local lgi = require 'lgi'
local Gio = lgi.Gio
local GObject = lgi.GObject

local core = require 'lgi.core'
local gi = core.gi

-- GOI < 1.30 did not map static factory method into interface
-- namespace.  The prominent example of this fault was that
-- Gio.File.new_for_path() had to be accessed as
-- Gio.file_new_for_path().  Create a compatibility layer to mask this
-- flaw.
for _, name in pairs { 'path', 'uri', 'commandline_arg' } do
   if not Gio.File['new_for_' .. name] then
      Gio.File._method['new_for_' .. name] = Gio['file_new_for_' .. name]
   end
end

-- Older versions of gio did not annotate input stream methods as
-- taking an array.  Apply workaround.
-- https://github.com/pavouk/lgi/issues/59
for _, name in pairs { 'read', 'read_all', 'read_async' } do
   local raw_read = Gio.InputStream._method[name]
   if gi.Gio.InputStream.methods[name].args[1].typeinfo.tag ~= 'array' then
      Gio.InputStream._method[name] = function(self, buffer, ...)
	 return raw_read(self, buffer, #buffer, ...)
      end
   end
end
