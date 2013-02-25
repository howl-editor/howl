------------------------------------------------------------------------------
--
--  LGI Support for repository packages (namespaces with classes
--  overriden in lgi)
--
--  Copyright (c) 2012 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local rawget, setmetatable, assert, error
   = rawget, setmetatable, assert, error

local core = require 'lgi.core'

-- Repo package metatable.
local package = { mt = {} }
package.mt.__index = package.mt

-- There is no lazy-loading, but define _resolve to do nothing to
-- achieve API compatibility with GI-based namespaces.
function package.mt:_resolve(recurse)
   return self
end

-- Defines new class, deriving from existing one.  If the class
-- already exists, does nothing and returns nil, otherwise returns
-- newly created class type.
function package.mt:class(name, parent, ...)
   if self[name] then return nil end
   local class = parent:derive(self._name .. '.' .. name, ...)
   self[name] = class
   return class
end

-- Makes sure that given package exists, creates it if it does not.
function package.ensure(name, version)
   local ns = rawget(core.repo, name)
   if not ns then
      ns = setmetatable({ _name = name, _version = version }, package.mt)
      core.repo[name] = ns
   else
      if version and ns._version and version ~= nv._version then
	 error(("%s-%s: required version %s "):format(
		  ns._name, ns._version, version))
      end
   end
   return ns
end

return package
