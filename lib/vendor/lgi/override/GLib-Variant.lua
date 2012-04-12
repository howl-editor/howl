------------------------------------------------------------------------------
--
--  LGI GLib Variant support implementation.
--
--  Copyright (c) 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local select, type, pairs, tostring, setmetatable, error, assert
   = select, type, pairs, tostring, setmetatable, error, assert

local lgi = require 'lgi'
local core = require 'lgi.core'
local bytes = require 'bytes'
local gi = core.gi
local GLib = lgi.GLib

local Variant = GLib.Variant
local variant_info = gi.GLib.Variant

-- Add custom methods for variant handling.
Variant._refsink = variant_info.methods.ref_sink
Variant._free = variant_info.methods.unref
Variant._setvalue = gi.GObject.Value.methods.set_variant
Variant._getvalue = gi.GObject.Value.methods.get_variant

-- Add 'type' property to variant, an alias to get_type().
Variant._attribute = { type = { get = Variant.get_type_string } }

local VariantBuilder = GLib.VariantBuilder
local VariantType = GLib.VariantType

-- VariantBuilder and VariantType are boxed only in glib-2.29 and
-- newer, add custom _free recipe for older glibs.
if not VariantBuilder._gtype then
   VariantBuilder._free = gi.GLib.VariantBuilder.methods.unref
end
if not VariantType._gtype then
   VariantBuilder._free = gi.GLib.VariantType.methods.free
end

-- Add constants containing basic variant types.
for k, v in pairs {
   BOOLEAN = 'b', BYTE = 'y', INT16 = 'n', UINT16 = 'q',
   INT32 = 'i', UINT32 = 'u', INT64 = 'x', UINT64 = 't',
   DOUBLE = 'd', STRING = 's', OBJECT_PATH = 'o', SIGNATURE = 'g',
   VARIANT = 'v', ANY = '*', BASIC = '?', MAYBE = 'm*', ARRAY = 'a*',
   TUPLE = 'r', UNIT = '()', DICT_ENTRY = '{?*}', DICTIONARY = 'a{?*}',
   STRING_ARRAY = 'as', BYTESTRING = 'ay',  BYTESTRING_ARRAY = 'aay',
} do VariantType[k] = VariantType.new(v) end

-- g_variant_get_type() is hidden by g-i (because scanner thinks that
-- this is GType getter), so provide manual override.
function Variant:get_type()
   return VariantType.new(Variant.get_type_string(self))
end

-- Implementation of Variant.new() from type and value.
local variant_new

local variant_basic_typemap = {
   b = 'boolean', y = 'byte', n = 'int16', q = 'uint16',
   i = 'int32', u = 'uint32', x = 'int64', t = 'uint64',
   d = 'double', s = 'string', o = 'object_path', g = 'signature', }

-- Checks validity of variant type format beginning at pos, return
-- position in format string after end of valid part.  Returns nil
-- when format is not valid.
local function read_format(format, pos, basic)
   local t = format:sub(pos, pos)
   pos = pos + 1
   if variant_basic_typemap[t] then
      return pos
   elseif basic then
      return nil
   elseif t =='v' then
      return pos
   elseif t == 'a' or t == 'm' then
      return read_format(format, pos)
   elseif t == '{' then
      pos = read_format(format, pos, true)
      if pos then pos = read_format(format, pos) end
      if not pos or format:sub(pos, pos) ~= '}' then return nil end
      return pos + 1
   elseif t == '(' then
      while format:sub(pos, pos) ~=  ')' do
	 pos = read_format(format, pos)
	 if not pos then return nil end
      end
      return pos + 1
   end
end

local function variant_new_basic(format, val)
   local func = variant_basic_typemap[format]
   if not func then return end
   local v = Variant['new_' .. func](val)
   if not v then
      error(("Variant.new(`%s') - invalid source value"):format(format))
   end
   return v
end

function variant_new(format, pos, val)
   local t = format:sub(pos, pos)
   pos = pos + 1
   local variant  = variant_new_basic(t, val)
   if variant then
      return variant, pos
   elseif t == 'v' then
      return Variant.new_variant(val), pos
   elseif t == 'm' then
      local epos
      if val then
	 variant, epos = variant_new(format, pos, val)
      else
	 epos = read_format(format, pos)
	 if not epos then return nil end
      end
      return Variant.new_maybe(VariantType.new(format:sub(pos, epos - 1)),
			       variant), epos
   elseif t == 'a' then
      if format:sub(pos, pos) == 'y' then
	 -- Bytestring is just simple Lua string.
	 return Variant.new_bytestring(val), pos + 1
      end
      local epos = read_format(format, pos)
      if not epos then return nil end
      local et = VariantType.new(format:sub(pos, epos - 1))
      local builder = VariantBuilder.new(VariantType.new_array(et))
      if et:is_subtype_of(VariantType.DICT_ENTRY) then
	 -- Map dictionary to Lua table directly.
	 for k, v in pairs(val) do
	    builder:add_value(Variant.new_dict_entry(
				 variant_new(format, pos + 1, k),
				 variant_new(format, pos + 2, v)))
	 end
      else
	 -- We have an issue with 'array with holes'. An attempt is
	 -- made here to work around it with 'n' field, if present.
	 for i = 1, val.n or #val do
	    builder:add_value(variant_new(format, pos, val[i]))
	 end
      end
      return builder:_end(), epos
   elseif t == '(' or t == '{' then
      -- Extract and check whole tuple or entry format.
      local epos = read_format(format, pos -1)
      if not epos then return nil end

      -- Prepare builder with specified format.
      local builder = VariantBuilder.new(
	 VariantType.new(format:sub(pos - 1, epos - 1)))

      -- Loop through provided value array and build variant using
      -- prepared builder.
      local i = 1
      while not format:sub(pos, pos):match('^[%)}]') do
	 local v, epos = variant_new(format, pos, val[i])
	 if not v then return nil end
	 builder:add_value(v)
	 pos = epos
	 i = i + 1
      end
      return builder:_end(), pos + 1
   end
end

-- Variant.new() is just a facade over variant_new backend.
function Variant.new(vt, val)
   if type(vt) ~= 'string' then vt = vt:dup_string() end
   local v, epos = variant_new(vt, 1, val)
   if not v or epos ~= #vt + 1 then
      error(("Variant.new(`%s') - invalid type"):format(vt))
   end
   return v
end
function Variant:_new(...) return Variant.new(...) end

-- Implement VariantBuilder:add() using the same facade.
function VariantBuilder:add(type, val)
   VariantBuilder.add_value(Variant.new(type, val))
end

-- Converts variant to nearest possible Lua value, but leaves arrays
-- intact (use indexing and/or iterators for handling arrays).
local simple_unpack_map = {
   b = 'boolean', y = 'byte', n = 'int16', q = 'uint16',
   i = 'int32', u = 'uint32', x = 'int64', t = 'uint64',
   d = 'double', s = 'string', o = 'string', g = 'string', v = 'variant'
}
local function variant_get(v)
   local type = v:get_type_string()
   local func = simple_unpack_map[type]
   if func then
      return Variant['get_' .. func](v)
   elseif type:match('^m') then
      return v:n_children() == 1 and variant_get(v:get_child_value(0)) or nil
   elseif type:match('^[{(r]') then
      -- Unpack dictionary entry or tuple into array.
      local array = { n = v:n_children() }
      for i = 1, array.n do
	 array[i] = variant_get(v:get_child_value(i - 1))
      end
      return array
   elseif Variant.is_of_type(v, VariantType.BYTESTRING) then
      return tostring(Variant.get_bytestring(v))
   elseif Variant.is_of_type(v, VariantType.DICTIONARY) then
      -- Return proxy table which dynamically looks up items in the
      -- target variant.
      local meta = {}
      if Variant.is_of_type(v, VariantType.new('a{s*}')) then
	 -- Use g_variant_lookup_value.
	 function meta:__index(key)
	    local found = Variant.lookup_value(v, key)
	    return found and variant_get(found)
	 end
      else
	 -- Custom search, walk key-by-key.  Cache key positions in
	 -- the meta table.
	 function meta:__index(key)
	    for i = 0, Variant.n_children(v) - 1 do
	       local entry = Variant.get_child_value(v, i)
	       local vkey = variant_get(Variant.get_child_value(entry, 0))
	       if vkey == key then
		  local found = Variant.get_child_value(entry, 1)
		  return found and variant_get(found)
	       end
	    end
	 end
      end
      return setmetatable({}, meta)
   end

   -- No simple unpacking is possible, return just self.  Complex
   -- compound types are meant to be accessed by indexing or
   -- iteration, implemented below.
   return v
end

-- Map simple unpacking to reading 'value' property.
Variant._attribute.value = { get = variant_get }

-- Define meaning of # and number-indexing to children access. Note
-- that GVariant g_asserts when these methods are invoked on variants
-- of inappropriate type, so we have to check manually before.
function Variant:_len()
   return self:is_container() and self:n_children() or 0
end

local variant_element = Variant._element
function Variant:_element(variant, name)
   -- If number is requested, consider it a special operation,
   -- indexing a variant.
   if type(name) == 'number' then return name, '_index' end
   return variant_element(self, variant, name)
end

function Variant:_access_index(variant, index, ...)
   assert(select('#', ...) == 0, 'GLib.Variant is not writable')
   if (Variant.is_container(variant) and
       Variant.n_children(variant) >= index) then
      return Variant.get_child_value(variant, index - 1).value
   end
end

-- Implementation of iterators over compound variant (simulating
-- standard Lua pairs() and ipairs() methods).
local function variant_inext(parent, index)
   index = index + 1
   if index <= #parent then
      return index, parent[index]
   end
end

function Variant:ipairs()
   return variant_inext, self, 0
end

function Variant:pairs()
   if self:is_of_type(VariantType.DICTIONARY) then
      -- For dictionaries, provide closure iterator which goes through
      -- all key-value pairs of the parent.
      local index = 0
      return function()
		index = index + 1
		if index <= #self then
		   local child = self[index]
		   return child[1], child[2]
		end
	     end
   end

   -- For non-dictionaries, pairs() is the same as ipairs().
   return self:ipairs()
end

-- Serialization support.  Override Variant:get_data() with safer
-- method which fills size to the resulting ref.
Variant._attribute.data = {}
function Variant._attribute.data:get()
   local buffer = bytes.new(Variant.get_size(self))
   Variant.store(self, buffer)
   return buffer
end

-- Map get_data to read-only 'data' property.

-- Override for new_from_data.  Takes care mainly about tricky
-- DestroyNotify handling.
local variant_new_from_data = Variant.new_from_data
function Variant.new_from_data(vt, data, trusted)
   if type(vt) == 'string' then vt = VariantType.new(vt) end
   if trusted == nil then trusted = true end
   return variant_new_from_data(
      vt, data, trusted,
      -- DestroyNotify implemented as closure which holds 'data' value
      -- as an upvalue.  The 'notify' argument is scope-async, which
      -- means that closure together with its upvalue will be
      -- destroyed after called.  Up to that time 'data' is safely
      -- held in upvalue for this closure.
      function() data = nil end)
end
