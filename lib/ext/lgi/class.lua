------------------------------------------------------------------------------
--
--  LGI Support for generic GType objects and interfaces
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local type, rawget, pairs, select, getmetatable, error
   = type, rawget, pairs, select, getmetatable, error
local string = require 'string'

local core = require 'lgi.core'
local gi = core.gi
local component = require 'lgi.component'
local record = require 'lgi.record'

-- Implementation of class and interface component loading.
local class = {
   class_mt = component.mt:clone(
      'class', { '_virtual', '_property', '_signal',
		 '_method', '_constant', '_field' }),
   interface_mt = component.mt:clone(
      'interface', { '_virtual', '_property', '_signal',
		     '_method', '_constant' }),
}

-- Checks whether given argument is type of this class.
function class.class_mt:is_type_of(instance)
   if type(instance) == 'userdata' then
      local instance_type = core.object.query(instance, 'repo')
      while instance_type do
	 if instance_type == self
	    or instance_type._implements[self._name] == self then
	    return true
	 end
	 instance_type = rawget(instance_type, '_parent')
      end
   end
   return false
end
class.interface_mt.is_type_of = class.class_mt.is_type_of

local function load_signal_name(name)
   name = name:match('^on_(.+)$')
   return name and name:gsub('_', '-')
end

local function load_signal_name_reverse(name)
   return 'on_' .. name:gsub('%-', '_')
end

local function load_vfunc_name(name)
   return name:match('^virtual_(.+)$')
end

local function load_vfunc_name_reverse(name)
   return 'virtual_' .. name
end

local function load_method(mi)
   local flags = mi.flags
   if not flags.is_getter and not flags.is_setter then
      return core.callable.new(mi)
   end
end

local function load_properties(info)
   return component.get_category(
      info.properties, nil,
      function(name) return string.gsub(name, '_', '-') end,
      function(name) return string.gsub(name, '%-', '_') end)
end

local function find_constructor(info)
   local name = info.name:gsub('([%d%l])(%u)', '%1_%2'):lower()
   local ctor = gi[info.namespace][name]

   -- Check that return value conforms to info type.
   if ctor then
      local ret = ctor.return_type.interface
      for walk in function(_, c) return c.parent end, nil, info do
	 if ret and walk == ret then
	    ctor = core.callable.new(ctor)
	    return function(self, ...) return ctor(...) end
	 end
      end
   end
end

-- Resolver for classes, recursively resolves also all parents and
-- implemented interfaces.
function class.class_mt:_resolve(recursive)
   -- Resolve itself using inherited implementation.
   component.mt._resolve(self)

   -- Go to parent and implemented interfaces and resolve them too.
   if recursive then
      for _, iface in pairs(self._implements or {}) do
	 iface:_resolve(recursive)
      end
      if self._parent then
	 self._parent:_resolve(recursive)
      end
   end
   return self
end

-- _element implementation for objects, checks parent and implemented
-- interfaces if element cannot be found in current typetable.
function class.class_mt:_element(instance, symbol)
   -- Check default implementation.
   local element, category = component.mt._element(self, instance, symbol)
   if element then return element, category end

   -- Special handling of '_native' attribute.
   if symbol == '_native' then return symbol, '_internal'
   elseif symbol == '_type' then return symbol, '_internal'
   end

   -- Check parent and all implemented interfaces.
   local parent = rawget(self, '_parent')
   if parent then
      element, category = parent:_element(instance, symbol)
      if element then return element, category end
   end
   local implements = rawget(self, '_implements') or {}
   for _, implemented in pairs(implements or {}) do
      element, category = implemented:_element(instance, symbol)
      if element then return element, category end
   end
end

-- Add accessor for 'internal' fields handling.
function class.class_mt:_access_internal(instance, element, ...)
   if select('#', ...) ~= 0 then return end
   if element == '_native' then
      return core.object.query(instance, 'addr')
   elseif element == '_type' then
      return core.object.query(instance, 'repo')
   end
end

-- Object constructor, does not accept any arguments.  Overriden later
-- Implementation of field accessor.  Note that compound fields are
-- not supported in classes (because they are not seen in the wild and
-- I'm lazy).
function class.class_mt:_access_field(instance, field, ...)
   return core.object.field(instance, field, ...)
end

-- Implementation of virtual method accessor.  Virtuals are
-- implemented by accessing callback pointer in the class struct of
-- the class.  Note that currently we support only reading of them,
-- writing would mean overriding, which is not supported yet.
function class.class_mt:_access_virtual(instance, vfunc, ...)
   if select('#', ...) > 0 then
      error(("%s: cannot override virtual `%s' "):format(
	       self._name, vfunc.name), 5)
   end
   -- Get typestruct of this class.
   local typestruct = core.object.query(instance, 'class',
					vfunc.container.gtype)

   -- Resolve the field of the typestruct with the virtual name.  This
   -- returns callback to the virtual, which can be directly called.
   return core.record.field(typestruct, self._class[vfunc.name])
end

function class.load_interface(namespace, info)
   -- Load all components of the interface.
   local interface = component.create(info, class.interface_mt)
   interface._property = load_properties(info)
   interface._method = component.get_category(info.methods, load_method)
   interface._signal = component.get_category(
      info.signals, nil, load_signal_name, load_signal_name_reverse)
   interface._constant = component.get_category(info.constants, core.constant)
   local type_struct = info.type_struct
   if type_struct then
      interface._virtual = component.get_category(
	 info.vfuncs, nil, load_vfunc_name, load_vfunc_name_reverse)
      interface._class = record.load(type_struct)
   end
   interface._new = find_constructor(info)
   return interface
end

function class.load_class(namespace, info)
   -- Find parent record, if available.
   local parent_info, parent = info.parent
   if parent_info then
      local ns, name = parent_info.namespace, parent_info.name
      if ns ~= namespace._name or name ~= info.name then
	 parent = core.repo[ns][name]
      end
   end

   -- Create class instance, copy mt from parent, if parent exists,
   -- otherwise defaults to class_mt.
   local class = component.create(
      info, parent and getmetatable(parent) or class.class_mt)
   class._parent = parent
   class._property = load_properties(info)
   class._method = component.get_category(info.methods, load_method)
   class._signal = component.get_category(
      info.signals, nil, load_signal_name, load_signal_name_reverse)
   class._constant = component.get_category(info.constants, core.constant)
   class._field = component.get_category(info.fields)
   local type_struct = info.type_struct
   if type_struct then
      class._virtual = component.get_category(
	 info.vfuncs, nil, load_vfunc_name, load_vfunc_name_reverse)
      class._class = record.load(type_struct)
      if parent then class._class._parent = parent._class end
   end

   -- Populate inheritation information (_implements and _parent fields).
   local interfaces, implements = info.interfaces, {}
   for i = 1, #interfaces do
      local iface = interfaces[i]
      implements[iface.fullname] = core.repo[iface.namespace][iface.name]
   end
   class._implements = implements
   class._new = find_constructor(info)
   return class
end

return class
