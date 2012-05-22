------------------------------------------------------------------------------
--
--  LGI Support for enums and bitflags
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local setmetatable, pairs, type = setmetatable, pairs, type
local core = require 'lgi.core'
local gi = core.gi
local component = require 'lgi.component'

local band, bor = core.band, core.bor

local enum = {
   enum_mt = component.mt:clone('enum', { '_method' }),
   bitflags_mt = component.mt:clone('flags', { '_method' }),
}

function enum.load(info, meta)
   local enum_type = component.create(info, meta)
   if info.methods then
      enum_type._method = component.get_category(
	 info.methods, core.callable.new)
   else
      -- Enum.methods was added only in GI1.30; for older gi, simulate
      -- the access using lookup in the global namespace.
      local prefix = info.name:gsub('%u+[^%u]+', '%1_'):lower()
      local namespace = core.repo[info.namespace]
      enum_type._method = setmetatable(
	 {}, { __index = function(_, name)
			    return namespace[prefix .. name]
			 end })
   end

   -- Load all enum values.
   local values = info.values
   for i = 1, #values do
      local mi = values[i]
      enum_type[mi.name:upper()] = mi.value
   end

   -- Install metatable providing reverse lookup (i.e name(s) by
   -- value).
   return enum_type
end

-- Enum reverse mapping, value->name.
function enum.enum_mt:_element(instance, value)
   if type(value) == 'number' then
      for name, val in pairs(self) do
	 if val == value then return name end
      end
      return value
   else
      return component.mt._element(self, instance, value)
   end
end

-- Constructs enum number from specified string.
function enum.enum_mt:_new(param)
   if type(param) == 'string' then param = self[param] end
   return param
end

-- Resolving arbitrary number to the table containing symbolic names
-- of contained bits.
function enum.bitflags_mt:_element(instance, value)
   if type(value) == 'number' then
      local result, remainder = {}, value
      for name, flag in pairs(self) do
	 if type(flag) == 'number' and name:sub(1, 1) ~= '_' and
	    band(value, flag) == flag then
	    result[name] = true
	    remainder = remainder - flag
	 end
      end
      if remainder > 0 then result[1] = remainder end
      return result
   else
      return component.mt._element(self, instance, value)
   end
end

-- 'Constructs' number from specified flags (or accepts just number).
function enum.bitflags_mt:_new(param)
   if type(param) == 'string' then
      return self[param]
   elseif type(param) == 'number' then
      return param
   else
      local num = 0
      for key, value in pairs(param) do
	 if type(key) == 'string' then value = key end
	 if type(value) == 'string' then value = self[value] end
	 num = bor(num, value)
      end
      return num
   end
end

return enum
