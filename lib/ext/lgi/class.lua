------------------------------------------------------------------------------
--
--  LGI Support for generic GType objects and interfaces
--
--  Copyright (c) 2010, 2011, 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local type, tostring, rawget, rawset, pairs, select,
getmetatable, setmetatable, error, assert
   = type, tostring, rawget, rawset, pairs, select,
   getmetatable, setmetatable, error, assert
local string = require 'string'

local core = require 'lgi.core'
local gi = core.gi
local component = require 'lgi.component'
local record = require 'lgi.record'
local ffi = require 'lgi.ffi'
local ti = ffi.types
local GObject = gi.require 'GObject'

-- Implementation of class and interface component loading.
local class = {
   class_mt = component.mt:clone(
      'class', { '_virtual', '_property', '_signal',
		 '_method', '_constant', '_field' }),
   interface_mt = component.mt:clone(
      'interface', { '_virtual', '_property', '_signal',
		     '_method', '_constant' }),
}

local type_class_peek = core.callable.new {
   addr = GObject.resolve.g_type_class_peek,
   ret = ti.ptr, ti.GType
}
local type_interface_peek = core.callable.new {
   addr = GObject.resolve.g_type_interface_peek,
   ret = ti.ptr, ti.ptr, ti.GType
}

local type_class = component.create(nil, record.struct_mt)
ffi.load_fields(type_class, { { 'g_type', ti.GType } })
local type_instance = component.create(nil, record.struct_mt)
ffi.load_fields(type_instance, { { 'g_class', type_class, ptr = true } })

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
   return name:match('^do_(.+)$')
end

local function load_vfunc_name_reverse(name)
   return 'do_' .. name
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
local internals = { _native = true, _type = true, _gtype = true,
		    _class = true, class = true }
function class.class_mt:_element(instance, symbol)
   -- Special handling of internal symbols.
   if internals[symbol] then return symbol, symbol end

   -- Check default implementation.
   local element, category = component.mt._element(self, instance, symbol)
   if element then return element, category end

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

-- Implementation of field accessor.  Note that compound fields are
-- not supported in classes (because they are not seen in the wild and
-- I'm lazy).
function class.class_mt:_access_field(instance, field, ...)
   return core.object.field(instance, field, ...)
end

-- Add accessor '_native' handling.
function class.class_mt:_access_native(instance)
   return core.object.query(instance, 'addr')
end

-- Add accessor '_type' handling.
function class.class_mt:_access_type(instance)
   return core.object.query(instance, 'repo')
end

-- Add accessor '_gtype' handling.
function class.class_mt:_access_gtype(instance)
   -- Cast address of the instance to TypeInstance to get to type info.
   local ti = core.record.new(type_instance,
			      core.object.query(instance, 'addr'))
   return ti.g_class.g_type
end

-- Add accessor '_class' handling.
function class.class_mt:_access_class(instance)
   local gtype = class.class_mt._access_gtype(self, instance)
   return core.record.new(self._class, type_class_peek(gtype))
end
class.class_mt._accessclass = class.class_mt._access_class

-- Add accessor '_virtual' handling.
function class.class_mt:_access_virtual(instance, vfi)
   local class_struct
   local container = vfi.container
   if container.is_interface then
      local gtype = class.class_mt._access_gtype(self, instance)
      local ptr = type_interface_peek(type_class_peek(gtype), container.gtype)
      class_struct = core.record.new(core.index[container.gtype]._class, ptr)
   else
      class_struct = class.class_mt._access_class(self, instance)
   end

   -- Retrieve proper method from the class struct.
   return class_struct[vfi.name]
end

-- Add __index for _virtual handling.  Convert vfi baseinfo into real
-- callable pointer according to the target type.
function class.class_mt:_index_virtual(vfi)
   -- Get proper class struct, either from class or interface.
   local ptr, class_struct = type_class_peek(self._gtype)
   if not ptr then return nil end
   local container = vfi.container
   if container.is_interface then
      local gtype = container._gtype
      local ptr = type_interface_peek(ptr, gtype)
      class_struct = core.record.new(core.index[gtype]._class, ptr)
   else
      class_struct = core.record.new(self._class, ptr)
   end

   -- Retrieve proper method from the class struct.
   return class_struct[vfi.name]
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
      interface._class._parent = core.repo.GObject.TypeInterface
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
      class._class._parent =
	 parent and parent._class or core.repo.GObject.TypeClass
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

local register_static = core.callable.new(GObject.type_register_static)
local type_query = core.callable.new(GObject.type_query)
local type_add_interface_static = core.callable.new(
   GObject.type_add_interface_static)
function class.class_mt:derive(typename, ifaces)
   -- Prepare repotable for newly registered class.
   local new_class = setmetatable(
      {
	 _parent = self, _override = {}, _guard = {}, _implements = {},
	 _element = class.derived_mt._element,
	 _class = self._class, _name = typename
      },
      class.derived_mt)

   -- Create class-initialization closure, which assigns pointers to
   -- all known overriden virtual methods.
   local function class_init(class_addr)
      -- Create instance of real class.
      local class_struct = core.record.new(new_class._class, class_addr)

      -- Iterate through all overrides and assign to the virtual callbacks.
      for name, addr in pairs(new_class._override) do
	 if type(addr) == 'userdata' then
	    class_struct[name] = addr
	 end
      end

      -- If type specified _class_init method, invoke it.
      local _class_init = rawget(new_class, '_class_init')
      if _class_init then
	 _class_init(new_class)
      end
   end
   local class_init_guard, class_init_addr = core.marshal.callback(
      GObject.ClassInitFunc, class_init)
   new_class._guard._class_init = class_init_guard

   -- Create instance initialization function.  Note that we do not
   -- pass directly user's method, because user will probably set it
   -- later after the type is already created, but we need to pass its
   -- address right now during type initialization.  Therefore, a stub
   -- which looks up the init method of the type dynamically is used
   -- instead.
   local function instance_init(instance)
      local _init = rawget(new_class, '_init')
      if _init then
	 -- Convert instance to real type and call init with it.
	 _init(core.object.new(core.record.query(instance, 'addr'),
	       false, true))
      end
   end
   local instance_init_guard, instance_init_addr = core.marshal.callback(
      GObject.InstanceInitFunc, instance_init)
   new_class._guard._instance_init = instance_init_guard

   -- Prepare GTypeInfo with the registration.
   local parent_info = type_query(self._gtype)
   local type_info = core.repo.GObject.TypeInfo {
      class_size = parent_info.class_size,
      class_init = class_init_addr,
      instance_size = parent_info.instance_size,
      instance_init = instance_init_addr,
   }

   -- Register new type with GType system.
   local gtype = register_static(self._gtype, typename:gsub('%.', ''),
				 type_info, {})
   rawset(new_class, '_gtype', core.gtype(gtype))
   if not new_class._gtype then
      error(("failed to derive `%s' from `%s'"):format(typename, self._name))
   end

   -- Add newly registered type into the lgi type index.
   core.index[new_class._gtype] = new_class

   -- Create interface initialization closures.
   for _, iface in pairs(ifaces or {}) do
      local override = {}
      new_class._override[iface._name] = override
      new_class._implements[iface._name] = iface

      -- Prepare interface initialization closure.
      local function iface_init(iface_addr)
	 local iface_struct = core.record.new(iface._class, iface_addr)

	 -- Iterate through all interface overrides and assign to the
	 -- virtual callbacks.
	 for name, addr in pairs(override) do
	    iface_struct[name] = addr
	 end
      end
      local iface_init_guard, iface_init_addr = core.marshal.callback(
	 GObject.InterfaceInitFunc, iface_init)
      new_class._guard['_iface_init_' .. iface._name] = iface_init_guard

      -- Hook up interface to the registered class.
      local iface_info = core.repo.GObject.InterfaceInfo {
	 interface_init = iface_init_addr,
      }
      type_add_interface_static(new_class, iface, iface_info)
   end

   return new_class
end

class.derived_mt = class.class_mt:clone('derived', {})

-- Support for 'priv' pseudomember, holding table with user
-- implementation data.
function class.derived_mt:_element(instance, symbol)
   -- Special handling of 'priv' attribute.
   if symbol == 'priv' then return symbol, '_priv' end

   -- Check default implementation.
   local element, category = class.class_mt._element(self, instance, symbol)
   if element then return element, category end
end

function class.derived_mt:_access_priv(instance, name, ...)
   if select('#', ...) > 0 then
      error(("%s: cannot assign `%s'"):format(self._name), name, 5)
   end
   return core.object.env(instance)
end

-- Overload __newindex to catch assignment to virtual - this causes
-- installation of new virtual method
function class.derived_mt:__newindex(name, target)
   -- Use _element method to get category to write to.
   local _element = (rawget(self, '_element')
		  or rawget(getmetatable(self), '_element'))
   local value, category = _element(self, nil, name)

   if category == '_virtual' then
      -- Overriding virtual method. Prepare callback to the target and
      -- store it to the _override type helper subtable.
      name = load_vfunc_name(name)
      local container = value.container
      local class_struct, override
      if container.is_interface then
	 class_struct = core.index[container.gtype]
	 override = self._override[class_struct._name]
	 class_struct = class_struct._class
      else
	 class_struct = self._class
	 override = self._override
      end
      local guard, vfunc = core.marshal.callback(
	 class_struct[name].typeinfo.interface, target)
      override[name] = vfunc
      self._guard[container.name .. ':' .. name] = guard
   else
      -- Simply assign to type.  This most probably means adding new
      -- member function to the class (or some static member).
      rawset(self, name, target)
   end
end

return class
