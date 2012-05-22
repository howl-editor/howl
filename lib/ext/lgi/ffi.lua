------------------------------------------------------------------------------
--
--  LGI Helpers for custom FFI definitions
--
--  Copyright (c) 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local pairs, ipairs, setmetatable, getmetatable
   = pairs, ipairs, setmetatable, getmetatable

local math = require 'math'
local lgi = require 'lgi'
local GObject = lgi.GObject

local core = require 'lgi.core'
local gi = core.gi
local component = require 'lgi.component'
local enum = require 'lgi.enum'
local record = require 'lgi.record'

local ffi = {}

local gobject = gi.require('GObject')
local glib = gi.require('GLib')

-- Gather all basic types.  We have to 'steal' them from well-known
-- declarations, because girepository API does not allow synthesizing
-- GIBaseInfo instances from the air.
ffi.types = {
   void = gobject.Callback.return_type,
   boolean = glib.Variant.methods.get_boolean.return_type,
   int8 = gobject.ParamSpecChar.fields.minimum.typeinfo,
   uint8 = gobject.ParamSpecUChar.fields.minimum.typeinfo,
   int16 = glib.Variant.methods.get_int16.return_type,
   uint16 = glib.Variant.methods.get_uint16.return_type,
   int32 = glib.Variant.methods.get_int32.return_type,
   uint32 = glib.Variant.methods.get_uint32.return_type,
   int64 = glib.Variant.methods.get_int64.return_type,
   uint64 = glib.Variant.methods.get_uint64.return_type,

   int = gobject.ParamSpecEnum.fields.default_value.typeinfo,
   uint = gobject.ParamSpecFlags.fields.default_value.typeinfo,
   long = gobject.ParamSpecLong.fields.default_value.typeinfo,
   ulong = gobject.ParamSpecULong.fields.default_value.typeinfo,

   float = gobject.ParamSpecFloat.fields.default_value.typeinfo,
   double = gobject.ParamSpecDouble.fields.default_value.typeinfo,

   utf8 = gobject.ParamSpecString.fields.default_value.typeinfo,
   filename = glib.file_get_contents.args[1].typeinfo,

   GType = gobject.ParamSpecGType.fields.is_a_type.typeinfo,

   ptr = glib.CompareDataFunc.args[1].typeinfo,
}

for name, alias in pairs {
   char = 'int8', uchar = 'uint8', short = 'int16', ushort = 'uint16'
} do
   ffi.types[name] = ffi.types[alias]
end

-- Gets gtype from specified resolved and _get_type function name.
function ffi.load_gtype(resolver, get_type_name)
   local addr = resolver[get_type_name]
   if not addr then return nil, ("`%s' not found"):format(get_type_name) end
   local get_gtype = core.callable.new(
      { name = get_type_name, addr = addr, ret = ffi.types.GType })
   return get_gtype()
end

-- Creates new enum/flags table with all values from specified gtype.
function ffi.load_enum(gtype, name)
   local is_flags = GObject.Type.is_a(gtype, GObject.Type.FLAGS)
   local enum_component = component.create(
      gtype, is_flags and enum.bitflags_mt or enum.enum_mt, name)
   local type_class = GObject.TypeClass.ref(gtype)
   local enum_class = core.record.cast(
      type_class, is_flags and GObject.FlagsClass or GObject.EnumClass)
   for i = 0, enum_class.n_values - 1 do
      local val = core.record.fromarray(enum_class.values, i)
      enum_component[val.value_nick:upper():gsub('%-', '_')] = val.value
   end
   type_class:unref()
   return enum_component
end

-- Aligns offset to specified alignment.
local function align(offset, align)
   return math.modf((offset + align - 1) / align) * align
end

-- Creates record from the table of the field definitions.
function ffi.load_fields(rec, defs)
   rec._field = {}
   local offset = 0
   local max_align = 1
   local max_size = 0
   for _, def in ipairs(defs) do
      local field = {}

      -- Get size and alignment of this field.
      local size, alignment
      if gi.isinfo(def[2]) then
	 field[2] = 0
	 if def[2].tag == 'interface' then
	    local ii = def[2].interface
	    if ii.type == 'enum' or ii.type == 'flags' then
	       size, alignment = core.marshal.typeinfo(ii.typeinfo)
	    elseif ii.type == 'struct' or ii.type == 'union' then
	       size, alignment = core.marshal.typeinfo(ffi.types.ptr)
	       if not ii.is_pointer then
		  -- Alignment is tricky; ideally we should go through
		  -- the record and find alignment according to the
		  -- largest alignments of the fields, but now we just
		  -- punt and use 'ptr' as alignment.  But this might
		  -- be incorrect in case that doubles are used on 32b
		  -- platform.

		  -- Get size from the record descriptor.
		  size = core.repotype(ii)._size
	       end
	    end
	 else
	    -- Basic type.
	    size, alignment = core.marshal.typeinfo(def[2])
	 end
      else
	 -- Either record or enum, decide according to repotable.
	 local repotype = getmetatable(def[2])._type
	 if repotype == 'struct' or repotype == 'union' then
	    field[2] = 1
	    size, alignment = core.marshal.typeinfo(ffi.types.ptr)
	    if not def.ptr then
	       field[2] = 2
	       size = def[2]._size
	    end
	 elseif repotype == 'enum' or 'repotype' == 'flags' then
	    field[2] = 3
	    field[4] = def.type or ffi.types.int
	    size, alignment = core.marshal.typeinfo(field[4])
	 end
      end

      -- Adjust offset according to the alignment.
      offset = align(offset, alignment)
      max_align = math.max(max_align, alignment)

      -- Create and add field definition.
      field[1] = offset
      field[3] = def[2]
      rec._field[def[1]] = field

      if getmetatable(rec)._type == 'union' then
	 -- Remember largest size as the size of the union.
	 max_size = math.max(max_size, align(size, alignment))
      else
	 -- Move offset after the field.
	 offset = offset + size
      end
   end

   -- Store the total size of the record.
   rec._size = ((getmetatable(rec)._type == 'union') and max_size
	     or align(offset, max_align))
end

return ffi
