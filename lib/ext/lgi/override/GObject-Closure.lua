------------------------------------------------------------------------------
--
--  LGI GClosure handling and marshalling of callables in GValues
--  arrays as arguments.
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local type, pairs, ipairs, unpack = type, pairs, ipairs, unpack or table.unpack

local core = require 'lgi.core'
local gi = core.gi
local repo = core.repo

local Type, Value = repo.GObject.Type, repo.GObject.Value

-- Implementation of closure support, together with marshalling.
local Closure = repo.GObject.Closure
local closure_info = gi.GObject.Closure

-- CallInfo is object based on GICallable, allowing marshalling
-- from/to GValue arrays.
local CallInfo = {}
CallInfo.__index = CallInfo

-- Compile callable_info into table which allows fast marshalling
function CallInfo.new(callable_info, to_lua)
   local self = setmetatable(
      { has_self = (callable_info.is_signal or callable_info.is_virtual) },
      CallInfo)
   local argc, gtype = 0

   -- If this is a C array with explicit length argument, mark it.
   local function mark_array_length(cell, ti)
      local len = ti.array_length
      if len then
	 cell.len_index = 1 + len + (self.has_self and 1 or 0)
	 if not self[cell.len_index] then self[cell.len_index] = {} end
	 self[cell.len_index].internal = true
      end
   end

   -- Fill in 'self' argument.
   if self.has_self then
      argc = 1
      gtype = callable_info.container.gtype
      self[1] = { dir = 'in', gtype = gtype,
		  [to_lua and 'to_lua' or 'to_value']
		  = Value.find_marshaller(gtype) }
   end

   -- Go through arguments.
   local phantom_return
   for i = 1, #callable_info.args do
      local ai = callable_info.args[i]
      local ti = ai.typeinfo

      -- Prepare parameter cell in self array.
      argc = argc + 1
      if not self[argc] then self[argc] = {} end
      local cell = self[argc]

      -- Fill in marshaller(s) for the cell.
      cell.dir = ai.direction
      cell.gtype = Type.from_typeinfo(ti)
      if (cell.dir == (to_lua and 'in' or 'out') or cell.dir == 'inout'
	  or (to_lua and cell.dir == 'out-caller-alloc')) then
	 cell.to_lua = Value.find_marshaller(
	    cell.gtype, ti, (ai.direction == 'inout'
			     and 'none' or ti.transfer))
      end
      if (cell.dir == (to_lua and 'out' or 'in') or cell.dir == 'inout'
	  or (not to_lua and cell.dir == 'out-caller-alloc')) then
	 cell.to_value = Value.find_marshaller(
	    cell.gtype, ti, (ai.direction == 'inout'
			     and 'none' or ti.transfer))
      end
      mark_array_length(cell, ti)

      -- Check for output parameters; if present, enable
      -- phantom-return heuristics.
      phantom_return = phantom_return or cell.dir == 'out'
   end

   -- Prepare retval marshalling.
   local ti = callable_info.return_type
   if ti.tag ~= 'void' or ti.is_pointer then
      gtype = Type.from_typeinfo(ti)
      local ret = { dir = 'out', gtype = gtype,
		    to_value = Value.find_marshaller(
		       gtype, ti, callable_info.return_transfer) }
      mark_array_length(ret, ti)
      if phantom_return and ti.tag == 'gboolean' then
	 self.phantom = ret
      else
	 self.ret = ret
      end
   end
   return self
end

-- Marshal single call_info cell (either input or output).
local function marshal_cell(
      call_info, cell, direction, args, argc,
      marshalling_params, value, params, retval)
   local marshaller = cell[direction]
   if not marshaller or cell.internal then return argc end
   argc = argc + 1
   local length_marshaller
   if cell.len_index then
      -- Prepare length argument marshaller.
      length_marshaller = call_info[cell.len_index][direction]
      if direction == 'to_lua' then
	 marshalling_params.length = length_marshaller(
	    params[cell.len_index], {})
      end
   end
   if direction == 'to_lua' then
      -- Marshal from GValue to Lua
      args[argc] = marshaller(value, marshalling_params)
   else
      -- Marshal from Lua to GValue
      marshaller(value, marshalling_params, args[argc])

      -- Marshal array length output, if applicable.
      if length_marshaller then
	 length_marshaller(params[cell.len_index], {},
			   marshalling_params.length)
      end

      -- Marshal phantom return, if applicable.
      if retval and call_info.phantom and args[argc] == nil then
	 call_info.phantom.to_value(retval, marshalling_params, false)
      end
   end
   return argc
end

-- Creates GClosure marshaller based on compiled CallInfo.
function CallInfo:get_closure_marshaller(target)
   return function(closure, retval, params)
      local marshalling_params = { keepalive = {} }
      local args, argc = {}, 0

      -- Marshal input arguments.
      for i = 1, #self do
	 argc = marshal_cell(
	    self, self[i], 'to_lua', args, argc,
	    marshalling_params, params[i], params)
      end

      -- Do the call.
      args = { target(unpack(args, 1, argc)) }
      argc = 0
      marshalling_params = { keepalive = {} }

      -- Marshall the return value.
      if self.ret and retval then
	 argc = marshal_cell(
	    self, self.ret, 'to_value', args, argc,
	    marshalling_params, retval, params)
      end

      -- Prepare 'true' into phantom return, will be reset to 'false'
      -- when some output argument is returned as 'nil'.
      if self.phantom and retval then
	 self.phantom.to_value(retval, marshalling_params, true)
      end

      -- Marshal output arguments.
      for i = 1, #self do
	 argc = marshal_cell(
	    self, self[i], 'to_value', args, argc,
	    marshalling_params, params[i], params, retval)
      end
   end
end

-- Marshalls Lua arguments into Values suitable for invoking closures
-- and signals.  Returns Value (for retval), array of Value (for
-- params) and keepalive value (which must be kept alive during the
-- call)
function CallInfo:pre_call(...)
   -- Prepare array of param values and initialize them with correct type.
   local params = {}
   for i = 1, #self do params[#params + 1] = Value(self[i].gtype) end
   local marshalling_params = { keepalive = {} }

   -- Marshal input values.
   local args, argc = { ... }, 0
   for i = 1, #self do
      argc = marshal_cell(
	 self, self[i], 'to_value', args, argc,
	 marshalling_params, params[i], params)
   end

   -- Prepare return value.
   local retval = Value()
   if self.ret then retval.type = self.ret.gtype end
   if self.phantom then retval.type = self.phantom.gtype end
   return retval, params, marshalling_params.keepalive
end

-- Unmarshalls Lua restuls from Values after invoking closure or
-- signal.  Returns all unmarshalled Lua values.
function CallInfo:post_call(params, retval)
   local marshalling_params = { keepalive = {} }
   local args, argc = {}, 0
   -- Check, whether phantom return exists and returned 'false'.  If
   -- yes, return just nil.
   if (self.phantom
       and not self.phantom.to_lua(retval, marshalling_params)) then
      return nil
   end

   -- Unmarshal return value.
   if self.ret and retval then
      argc = marshal_cell(
	 self, self.ret, 'to_lua', args, argc,
	 marshalling_params, retval, params)
   end

   -- Unmarshal output arguments.
   for i = 1, #self do
      argc = marshal_cell(
	 self, self[i], 'to_lua', args, argc,
	 marshalling_params, params[i], params)
   end

   -- Return all created Lua values.
   return unpack(args, 1, argc)
end

-- Create new closure invoking Lua target function (or anything else
-- that can be called).  Optionally callback_info specifies detailed
-- information about how to marshal signals.
function Closure:_new(target, callback_info)
   local closure = Closure._method.new_simple(closure_info.size, nil)
   if target then
      local marshaller
      if callback_info then
	 -- Create marshaller based on callinfo.
	 local call_info = CallInfo.new(callback_info, true)
	 marshaller = call_info:get_closure_marshaller(target)
      else
	 -- Create marshaller based only on Value types.
	 function marshaller(closure, retval, params)
	    local args = {}
	    for i, val in ipairs(params) do args[i] = val.value end
	    local ret = target(unpack(args, 1, #params))
	    if retval then retval.value = ret end
	 end
      end
      core.marshal.closure_set_marshal(closure, marshaller)
   end
   Closure.ref(closure)
   Closure.sink(closure)
   return closure
end

-- Export CallInfo as field of Closure.
Closure.CallInfo = CallInfo
