------------------------------------------------------------------------------
--
--  LGI Basic repo type component implementation
--
--  Copyright (c) 2010, 2011, 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local assert, pcall, setmetatable, getmetatable, pairs, next, rawget, rawset,
type, select, error
   = assert, pcall, setmetatable, getmetatable, pairs, next, rawget, rawset,
type, select, error

local table = require 'table'
local string = require 'string'
local core = require 'lgi.core'

-- Generic component metatable.  Component is any entity in the repo,
-- e.g. record, object, enum, etc.
local component = { mt = {} }

-- Creates new component table by cloning all contents and setting
-- Gets table for category of compound (i.e. _field of struct or _property
-- for class etc).  Installs metatable which performs on-demand lookup of
-- symbols.
function component.get_category(children, xform_value,
				xform_name, xform_name_reverse)
   -- Either none or both transform methods must be provided.
   assert(not xform_name or xform_name_reverse)

   -- Early shortcircuit; no elements, no table needed at all.
   if #children == 0 then return nil end

   -- Index contains array of indices which were still not retrieved
   -- from 'children' table, and table part contains name->index
   -- mapping.
   local index, mt = {}, {}
   for i = 1, #children do index[i] = i end

   -- Fully resolves the category (i.e. loads everything remaining to
   -- be loaded in given category) and disconnects on-demand loading
   -- metatable.
   local function resolve(category)
      -- Load al values from unknown indices.
      local ei, en, val
      local function xvalue(arg)
	 if not xform_value then return arg end
	 if arg then
	    local ok, res = pcall(xform_value, arg)
	    return ok and res
	 end
      end
      while #index > 0 do
	 ei = children[table.remove(index)]
	 val = xvalue(ei)
	 if val then
	    en = ei.name
	    en = not xform_name_reverse and en or xform_name_reverse(en)
	    if en then category[en] = val end
	 end
      end

      -- Load all known indices.
      for en, idx in pairs(index) do
	 val = xvalue(children[idx])
	 en = not xform_name_reverse and en or xform_name_reverse(en)
	 if en then category[en] = val end
      end

      -- Metatable is no longer needed, disconnect it.
      return setmetatable(category, nil)
   end

   function mt:__index(requested_name)
      -- Check if closure for fully resolving the category is needed.
      if requested_name == '_resolve' then return resolve end

      -- Transform name by transform function.
      local name = not xform_name and requested_name
	 or xform_name(requested_name)
      if not name then return end

      -- Check, whether we already know its index.
      local idx, val = index[name]
      if idx then
	 -- We know at least the index, so get info directly.
	 val = children[idx]
	 index[name] = nil
      else
	 -- Not yet, go through unknown indices and try to find the
	 -- name.
	 while #index > 0 do
	    idx = table.remove(index)
	    val = children[idx]
	    local en = val.name
	    if en == name then break end
	    val = nil
	    index[en] = idx
	 end
      end

      -- If there is nothing in the index, we can disconnect
      -- metatable, because everything is already loaded.
      if not next(index) then
	 setmetatable(self, nil)
      end

      -- Transform found value and store it into the category (self)
      -- table.
      if not val then return nil end
      if xform_value then val = xform_value(val) end
      if not val then return nil end
      self[requested_name] = val
      return val
   end
   return setmetatable({}, mt)
end

-- Creates new component table by cloning all contents and setting
-- categories table.
function component.mt:clone(type, categories)
   local new_component = {}
   for key, value in pairs(self) do new_component[key] = value end
   new_component._type = type
   if categories then
      table.insert(categories, 1, '_attribute')
      new_component._categories = categories
   end
   return new_component
end

-- __index implementation, uses _element method to perform lookup.
function component.mt:__index(key)
   -- First try to invoke our own _element method.
   local _element, mt = rawget(self, '_element')
   if not _element then
      mt = getmetatable(self)
      _element = rawget(mt, '_element')
   end
   local value = _element(self, nil, key)
   if value then return value end

   -- If not found as object element, examine the metatable itself.
   return rawget(mt or getmetatable(self), key)
end

-- __call implementation, uses _new method to create new instance of
-- component type.
function component.mt:__call(...)
   return self:_new(...)
end

-- Fully resolves the whole typetable, i.e. load all symbols normally
-- loaded on-demand at once.  Returns self, so that resolve can be
-- easily chained for the caller.
function component.mt:_resolve()
   local categories = self._categories or {}
   for i = 1, #categories do
      -- Invoke '_resolve' function for all category tables, if they have it.
      local category = rawget(self, categories[i])
      local resolve = type(category) == 'table' and category._resolve
      if resolve then resolve(category) end
   end
   return self
end

-- Implementation of _access method, which is called by _core when
-- repo instance is accessed for reading or writing.
function component.mt:_access(instance, symbol, ...)
   -- Invoke _element, which converts symbol to element and category.
   local element, category = self:_element(instance, symbol)
   if not element then
      error(("%s: no `%s'"):format(self._name, symbol), 3)
   end
   return self:_access_element(instance, category, symbol, element, ...)
end

-- Internal worker of access, which works over already resolved element.
function component.mt:_access_element(instance, category, symbol, element, ...)
   -- Get category handler to be used, and invoke it.
   if category then
      local handler = self['_access' .. category]
      if handler then return handler(self, instance, element, ...) end
   end

   -- If specific accessor does not exist, consider the element to be
   -- 'static const' attribute of the class.  This works well for
   -- methods, constants and assorted other elements added manually
   -- into the class by overrides.
   if select('#', ...) > 0 then
      error(("%s: `%s' is not writable"):format(self._name, symbol), 4)
   end
   return element
end

-- Keyword translation dictionary.  Used for translating Lua keywords
-- which might appear as symbols in typelibs into Lua-neutral identifiers.
local keyword_dictionary = {
   _end = 'end', _do = 'do', _then = 'then', _elseif = 'elseif', _in = 'in',
   _local = 'local', _function = 'function', _nil = 'nil', _false = 'false',
   _true = 'true', _and = 'and', _or = 'or', _not = 'not',
}

-- Retrieves (element, category) pair from given componenttable and
-- instance for given symbol.
function component.mt:_element(instance, symbol)
   -- This generic version can work only with strings.  Refuse
   -- everything other, hoping that some more specialized _element
   -- implementation will handle it.
   if type(symbol) ~= 'string' then return end

   -- Check keyword translation dictionary.  If the symbol can be
   -- found there, try to lookup translated symbol.
   symbol = keyword_dictionary[symbol] or symbol

   -- Check whether symbol is directly accessible in the component.
   local element = rawget(self, symbol)
   if element then return element end

   -- Decompose symbol name, in case that it contains category prefix
   -- (e.g. '_field_name' when requesting explicitely field called
   -- name).
   local category, name = string.match(symbol, '^(_.-)_(.*)$')
   if category and name and category ~= '_access' then
      -- Check requested category.
      local cat = rawget(self, category)
      element = cat and cat[name]
   elseif string.sub(symbol, 1, 1) ~= '_' then
      -- Check all available categories.
      local categories = self._categories or {}
      for i = 1, #categories do
	 category = categories[i]
	 local cat = rawget(self, category)
	 element = cat and cat[symbol]
	 if element then break end
      end
   end
   if element then
      -- Make sure that table-based attributes have symbol name, so
      -- that potential errors contain the name of referenced
      -- attribute.
      if type(element) == 'table' and category == '_attribute' then
	 element._name = element._name or symbol
      end
      return element, category
   end
end

-- Implementation of attribute accessor.  Attribute is either function
-- to be directly invoked, or table containing set and get functions.
function component.mt:_access_attribute(instance, element, ...)
   -- If element is a table, assume that this table contains 'get' and
   -- 'set' methods.  Dispatch to them, and error out if they are
   -- missing.
   if type(element) == 'table' then
      local mode = select('#', ...) == 0 and 'get' or 'set'
      if not element[mode] then
	 error(("%s: cannot %s `%s'"):format(
		  self._name, mode == 'get' and 'read' or 'write',
		  element._name or '<unknown>'), 5)
      end
      element = element[mode]
   end

   -- Invoke attribute access function.
   return element(instance, ...)
end

-- Creates new component and sets up common parts according to given
-- info.
function component.create(info, mt, name)
   local gtype
   if core.gi.isinfo(info) then
      gtype = info.gtype
      name = info.fullname
   else
      gtype = info and core.gtype(info)
   end

   -- Fill in meta of the compound.
   local component = { _name = name }
   if gtype then
      -- Bind component in repo, make the relation using GType.
      component._gtype = gtype
      core.index[gtype] = component
   end
   return setmetatable(component, mt)
end

return component
