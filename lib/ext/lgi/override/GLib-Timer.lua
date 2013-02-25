-------------------------------------------------------------------------------
--
-- LGI GLib Timer support implementation.
--
-- Copyright (c) 2013 Pavel Holejsovsky
-- Licensed under the MIT license:
-- http://www.opensource.org/licenses/mit-license.php
--
-------------------------------------------------------------------------------

local pairs = pairs

local lgi = require 'lgi'
local core = require 'lgi.core'
local record = require 'lgi.record'
local ffi = require 'lgi.ffi'
local ti = ffi.types

local Timer = lgi.GLib.Timer:_resolve(true)

local module = core.gi.GLib.resolve
for name, def in pairs {
   new = { ret = { Timer, xfer = true } },
   elapsed = { ret = ti.double, { Timer }, { ti.ulong, dir = 'out' } },
} do
   local _ = Timer[name]
   def.addr = module['g_timer_' .. name]
   Timer._method[name] = core.callable.new(def)
end

Timer._free = core.gi.GLib.Timer.methods.destroy
Timer._method.destroy = nil
Timer._new = function(_, ...) return Timer.new(...) end
