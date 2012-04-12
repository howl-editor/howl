------------------------------------------------------------------------------
--
--  LGI Handling of structs and unions
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local rawget, assert, select, pairs, type, error, setmetatable
   = rawget, assert, select, pairs, type, error, setmetatable

-- Require core lgi utilities, used during bootstrap.
local core = require 'lgi.core'
local gi = core.gi
local component = require 'lgi.component'

-- Implementation of record_mt, which is inherited from component
-- and provides customizations for structures and unions.
local record = { mt = component.mt:clone { '_method', '_field' } }

-- Checks whether given argument is type of this class.
function record.mt:is_type_of(instance)
   if type(instance) == 'userdata' then
      local instance_type = core.record.query(instance, 'repo')
      while instance_type do
	 if instance_type == self then return true end
	 instance_type = rawget(instance_type, '_parent')
      end
   end
   return false
end

function record.mt:_element(instance, symbol)
   -- First of all, try normal inherited functionality.
   local element, category = component.mt._element(self, instance, symbol)
   if element then return element, category end

   -- If the record has parent struct, try it there.
   local parent = rawget(self, '_parent')
   if parent then
      element, category = parent:_element(instance, symbol)
      if element then
	 -- If category shows that returned element is already from
	 -- inherited, leave it so, otherwise wrap returned element
	 -- into _inherited category.
	 if category ~= '_inherited' then
	    element = { element = element, category = category,
			symbol = symbol, type = parent }
	    category = '_inherited'
	 end
	 return element, category
      end
   end
end

-- Add accessor for handling fields.
function record.mt:_access_field(instance, element, ...)
   assert(gi.isinfo(element) and element.is_field)
   -- Check the type of the field.
   local ii = element.typeinfo.interface
   if ii and (ii.type == 'struct' or ii.type == 'union') then
      -- Nested structure, handle assignment to it specially.  Get
      -- access to underlying nested structure.
      local subrecord = core.record.field(instance, element)

      -- Reading it is simple, we are done.
      if select('#', ...) == 0 then return subrecord end

      -- Writing means assigning all fields from the source table.
      for name, value in pairs(...) do subrecord[name] = value end
   else
      -- In other cases, just access the instance using given info.
      return core.record.field(instance, element, ...)
   end
end

-- Add accessor for accessing inherited elements.
function record.mt:_access_inherited(instance, element, ...)
   -- Cast instance to inherited type.
   instance = core.record.cast(instance, element.type)

   -- Forward to normal _access_element implementation.
   return self:_access_element(instance, element.category, element.symbol,
			       element.element, ...)
end

-- Create structure instance and initialize it with given fields.
function record.mt:_new(fields)
   -- Find baseinfo of requested record.
   local info
   if self._gtype then
      -- Try to lookup info by gtype.
      info = gi[self._gtype]
   end
   if not info then
      -- GType is not available, so lookup info by name.
      local ns, name = self._name:match('^(.-)%.(.+)$')
      info = assert(gi[ns][name])
   end

   -- Create the structure instance.
   local struct = core.record.new(info)

   -- Set values of fields.
   for name, value in pairs(fields or {}) do struct[name] = value end
   return struct
end

-- Loads structure information into table representing the structure
function record.load(info)
   local record = component.create(info, record.mt)
   record._method = component.get_category(info.methods, core.callable.new)
   record._field = component.get_category(info.fields)

   -- Check, whether global namespace contains 'constructor' method,
   -- i.e. method which has the same name as our record type (except
   -- that type is in CamelCase, while method is
   -- under_score_delimited).  If not found, check for 'new' method.
   local func = info.name:gsub('([%l%d])([%u])', '%1_%2'):lower()
   local ctor = gi[info.namespace][func]
   if not ctor then ctor = info.methods.new end

   -- Check, whether ctor is valid.  In order to be valid, it must
   -- return instance of this record.
   if (ctor and ctor.return_type.tag =='interface'
       and ctor.return_type.interface == info) then
      ctor = core.callable.new(ctor)
      record._new = function(typetable, ...) return ctor(...) end
   end
   return record
end

return record
