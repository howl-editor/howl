------------------------------------------------------------------------------
--
--  LGI GObject.Value support.
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local assert, pairs, select, type, tostring, error =
   assert, pairs, select, type, tostring, error
local lgi = require 'lgi'
local core = require 'lgi.core'
local repo = core.repo
local gi = core.gi
local Type = repo.GObject.Type

-- Value is constructible from any kind of source Lua value, and the
-- type of the value can be hinted by type name.
local Value = repo.GObject.Value
local value_info = gi.GObject.Value

local log = lgi.log.domain('Lgi')

-- Workaround for incorrect annotations - g_value_set_xxx are missing
-- (allow-none) annotations in glib < 2.30.
for _, name in pairs { 'set_object', 'set_variant', 'set_string' } do
   if not value_info.methods[name].args[1].optional then
      log.message("g_value_%s() is missing (allow-none)", name)
      local setter = Value[name]
      Value._method[name] =
      function(value, val)
	 if not val then Value.reset(value) else setter(value, val) end
      end
   end
end

-- Do not allow direct access to fields.
local value_field_gtype = Value._field.g_type
Value._field = nil

-- 'type' property controls gtype of the property.
Value._attribute = { gtype = {} }
function Value._attribute.gtype.get(value)
   return core.record.field(value, value_field_gtype)
end
function Value._attribute.gtype.set(value, newtype)
   local gtype = core.record.field(value, value_field_gtype)
   if gtype then
      if newtype then
	 -- Try converting old value to new one.
	 local dest = core.record.new(value_info)
	 Value.init(dest, newtype)
	 if not Value.transform(value, dest) then
	    error(("GObject.Value: cannot convert `%s' to `%s'"):format(
		     gtype, core.record.field(dest, value_field_gtype)))
	 end
	 Value.unset(value)
	 Value.init(value, newtype)
	 Value.copy(dest, value)
      else
	 Value.unset(value)
      end
   elseif newtype then
      -- No value was set and some is requested, so set it.
      Value.init(value, newtype)
   end
end

local value_marshallers = {}
for name, gtype in pairs(Type) do
   local get = Value._method['get_' .. name:lower()]
   local set = Value._method['set_' .. name:lower()]
   if get and set then
      value_marshallers[gtype] =
      function(value, params, ...)
	 return (select('#', ...) > 0 and set or get)(value, ...)
      end
   end
end

-- Interface marshaller is the same as object marshaller.
value_marshallers[Type.INTERFACE] = value_marshallers[Type.OBJECT]

-- Override 'boxed' marshaller, default one marshalls to gpointer
-- instead of target boxed type.
value_marshallers[Type.BOXED] =
function(value, params, ...)
   local gtype = core.record.field(value, value_field_gtype)
   if select('#', ...) > 0 then
      Value.set_boxed(value, core.record.query((...), 'addr', gtype))
   else
      return core.record.new(gi[core.gtype(gtype)], Value.get_boxed(value))
   end
end

-- Override marshallers for enums and bitmaps, marshal them as strings
-- or sets of string flags.
for name, gtype in pairs { ENUM = Type.ENUM, FLAGS = Type.FLAGS } do
   local get = Value._method['get_' .. name:lower()]
   local set = Value._method['set_' .. name:lower()]
   value_marshallers[gtype] = function(value, params, ...)
      local rtype
      if select('#', ...) > 0 then
	 local param = ...
	 if type(param) ~= 'number' then
	    rtype = core.repotype(core.record.field(value, value_field_gtype))
	    param = rtype(param)
	 end
	 set(value, param)
      else
	 rtype = core.repotype(core.record.field(value, value_field_gtype))
	 return rtype[get(value)]
      end
   end
end

-- Create GStrv marshaller, implement it using typeinfo marshaller
-- with proper null-terminated-array-of-utf8 typeinfo 'stolen' from
-- g_shell_parse_argv().
value_marshallers[Type.STRV] = core.marshal.container(
   gi.GLib.shell_parse_argv.args[3].typeinfo)

-- Finds marshaller closure which can marshal type described either by
-- gtype or typeinfo/transfer combo.
function Value._method.find_marshaller(gtype, typeinfo, transfer)
   -- Check whether we can have marshaller for typeinfo, if the
   -- typeinfo is container.
   local marshaller
   if typeinfo then
      marshaller = core.marshal.container(typeinfo, transfer)
      if marshaller then return marshaller end
   end

   -- Special case for non-gtype records.
   if not gtype and typeinfo and typeinfo.tag == 'interface' then
      -- Workaround for GoI < 1.30; it does not know that GLib structs are
      -- boxed, so it does not assign them GType; moreover it incorrectly
      -- considers GParamSpec as GType-less struct instead of the class.
      local function marshal_record_no_gtype(value, params, ...)
	 -- Check actual gtype of the real value.
	 local gtype = core.record.field(value, value_field_gtype)

	 if Type.is_a(gtype, Type.PARAM) then
	    return value_marshallers[Type.PARAM](value, ...)
	 end

	 -- Find out proper getter/setter method for the value.
	 local get, set
	 if Type.is_a(gtype, Type.BOXED) then
	    get, set = Value.get_boxed, Value.set_boxed
	 else
	    get, set = Value.get_pointer, Value.set_pointer
	 end

	 -- Do GValue<->record transfer.
	 local record_info = typeinfo.interface
	 if select('#', ...) > 0 then
	    set(value, core.record.query((...), 'addr', record_info))
	 else
	    return core.record.new(record_info, get(value))
	 end
      end
      return marshal_record_no_gtype
   end

   local gt = gtype
   if type(gt) == 'userdata' then gt = Type.name(gt) end

   -- Special marshaller, allowing only 'nil'.
   if not gt then return function() end end

   -- Find marshaller according to gtype of the value.
   while gt do
      -- Check simple and/or fundamental marshallers.
      marshaller = value_marshallers[gt] or core.marshal.fundamental(gt)
      if marshaller then return marshaller end
      gt = Type.parent(gt)
   end
   error(("GValue marshaller for `%s' not found"):format(tostring(gtype)))
end

-- Value 'value' property provides access to GValue's embedded data.
function Value._attribute:value(...)
   local marshaller = Value._method.find_marshaller(
      core.record.field(self, value_field_gtype))
   return marshaller(self, nil, ...)
end

-- Implement custom 'constructor', taking optionally two values (type
-- and value).  The reason why it is overriden is that the order of
-- initialization is important, and standard record intializer cannot
-- enforce the order.
function Value:_new(gtype, value)
   local v = core.record.new(value_info)
   if gtype then v.gtype = gtype end
   if value then v.value = value end
   return v
end
