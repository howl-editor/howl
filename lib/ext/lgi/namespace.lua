------------------------------------------------------------------------------
--
--  LGI Support for repository namespace
--
--  Copyright (c) 2010, 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local type, rawget, next, pairs, require, pcall, setmetatable, assert
   = type, rawget, next, pairs, require, pcall, setmetatable, assert
local package = require 'package'
local core = require 'lgi.core'
local enum = require 'lgi.enum'
local component = require 'lgi.component'
local record = require 'lgi.record'
local class = require 'lgi.class'

-- Table containing loaders for various GI types, indexed by
-- gi.InfoType constants.
local typeloader = {}

typeloader['function'] =
   function(namespace, info)
      return core.callable.new(info), '_function'
   end

function typeloader.constant(namespace, info)
   return core.constant(info), '_constant'
end

function typeloader.enum(namespace, info)
   return enum.load(info, enum.enum_mt), '_enum'
end

function typeloader.flags(namespace, info)
   return enum.load(info, enum.bitflags_mt), '_enum'
end

function typeloader.struct(namespace, info)
   -- Avoid exposing internal structs created for object implementations.
   if not info.is_gtype_struct then
      return record.load(info), '_struct'
   end
end

function typeloader.union(namespace, info)
   return record.load(info), '_union'
end

function typeloader.interface(namespace, info)
   return class.load_interface(namespace, info), '_interface'
end

function typeloader.object(namespace, info)
   return class.load_class(namespace, info), '_class'
end

-- Repo namespace metatable.
local namespace = {
   mt = {
      _categories = { '_class', '_interface', '_struct', '_union', '_enum',
		      '_function', '_constant', } }
}

-- Gets symbol of the specified namespace, if not present yet, tries to load it
-- on-demand.
function namespace.mt:__index(symbol)
   -- Check whether symbol is present in the metatable.
   local val = namespace.mt[symbol]
   if val then return val end

   -- Check, whether there is some precondition in the lazy-loading table.
   local preconditions = rawget(self, '_precondition')
   local precondition = preconditions and preconditions[symbol]
   if precondition then
      local package = preconditions[symbol]
      if not preconditions[package] then
	 preconditions[package] = true
	 require('lgi.override.' .. package)
	 preconditions[package] = nil
      end
      preconditions[symbol] = nil
      if not next(preconditions) then self._precondition = nil end
   end

   -- Check, whether symbol is already loaded.
   val = component.mt._element(self, nil, symbol, namespace.mt._categories)
   if val then return val end

   -- Lookup baseinfo of requested symbol in the GIRepository.
   local info = core.gi[self._name][symbol]
   if not info then return nil end

   -- Decide according to symbol type what to do.
   local loader = typeloader[info.type]
   if loader then
      local category
      val, category = loader(self, info)

      -- Cache the symbol in specified category in the namespace.
      if val then
	 local cat = rawget(self, category)
	 if not cat then
	    cat = {}
	    self[category] = cat
	 end
	 -- Store symbol into the repo, but only if it is not already
	 -- there.  It could by added to repo as byproduct of loading
	 -- other symbol.
	 if not cat[symbol] then cat[symbol] = val end
      elseif info.is_gtype_struct then
	 -- If we have XxxClass name, try to lookup class structure of
	 -- the Xxx object.
	 local class = (symbol:match('^(%w+)Class$')
		     or symbol:match('^(%w+)Iface$')
		  or symbol:match('^(%w+)Interface$'))
	 if class then
	    class = self[class]
	    if class then val = class._class end
	 end
      end
   else
      val = info
   end
   return val
end

-- Resolves everything in the namespace by iterating through it.
function namespace.mt:_resolve(recurse)
   -- Iterate through all items in the namespace and dereference them,
   -- which causes them to be loaded in and cached inside the namespace
   -- table.
   local gi_ns = core.gi[self._name]
   for i = 1, #gi_ns do
      local ok, component = pcall(function() return self[gi_ns[i].name] end)
      if ok and recurse and type(component) == 'table' then
	 local resolve = component._resolve
	 if resolve then resolve(component, recurse) end
      end
   end
   return self
end

-- Makes sure that the namespace (optionally with requested version)
-- is properly loaded.
function namespace.require(name, version)
   -- Load the namespace info for GIRepository.  This also verifies
   -- whether requested version can be loaded.
   local ns_info = assert(core.gi.require(name, version))

   -- If the repository table does not exist yet, create it.
   local ns = rawget(core.repo, name)
   if not ns then
      ns = setmetatable({ _name = name, _version = ns_info.version,
			  _dependencies = ns_info.dependencies },
			namespace.mt)
      core.repo[name] = ns

      -- Make sure that all dependent namespaces are also loaded.
      for name, version in pairs(ns._dependencies or {}) do
	 namespace.require(name, version)
      end

      -- Try to load override, if it is present.
      local override_name = 'lgi.override.' .. ns._name
      local ok, msg = pcall(require, override_name)
      if not ok then
	 -- Try parsing message; if it is something different than
	 -- "module xxx not found", then attempt to load again and let
	 -- the exception fly out.
	 if not msg:find("module '" .. override_name .. "' not found:",
			 1, true) then
	    package.loaded[override_name] = nil
	    require(override_name)
	 end
      end
   end
   return ns
end

return namespace
