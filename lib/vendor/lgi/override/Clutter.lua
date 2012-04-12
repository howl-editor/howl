------------------------------------------------------------------------------
--
--  LGI Clutter override module.
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local select, type, pairs = select, type, pairs
local lgi = require 'lgi'
local core = require 'lgi.core'
local Clutter = lgi.Clutter

Clutter.Container._attribute = {}

function Clutter.Container:add(...)
   local args = { ... }
   for i = 1, #args do Clutter.Container.add_actor(self, args[i]) end
end

-- Provides pseudo-attribute 'meta' for accessing container's
-- child-meta elements.
local container_child_meta_mt = {}
function container_child_meta_mt:__index(child)
   return self._container:get_child_meta(child)
end
Clutter.Container._attribute.meta = {}
function Clutter.Container._attribute.meta:get()
   return setmetatable({ _container = self }, container_child_meta_mt)
end

-- Take over internal Clutter synchronization lock.
core.registerlock('Clutter', 'clutter_threads_set_lock_functions')

-- Initialize clutter with threading.
Clutter.threads_init()

-- Automatically initialize clutter, avoid continuing if
-- initialization fails.
local status = Clutter.init()
if status ~= 'SUCCESS' then
   error(("Clutter initialization failed: %s"):format(status))
end
