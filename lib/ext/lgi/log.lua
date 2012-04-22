------------------------------------------------------------------------------
--
--  LGI support for GLib-based logging.
--
--  Copyright (c) 2011 Pavel Holejsovsky
--  Licensed under the MIT license:
--  http://www.opensource.org/licenses/mit-license.php
--
------------------------------------------------------------------------------

local pcall, ipairs = pcall, ipairs
local string = require 'string'
local core = require 'lgi.core'

local log = {}

-- Creates table containing methods 'message', 'warning', 'critical', 'error',
-- 'debug' methods which log to specified domain.
function log.domain(name)
   local domain = log[name] or {}
   for _, level in ipairs { 'message', 'warning', 'critical',
			    'error', 'debug' } do
      if not domain[level] then
	 domain[level] =
	    function(format, ...)
	       local ok, msg = pcall(string.format, format, ...)
	       if not ok then
		  msg = ("BAD FMT: `%s', `%s'"):format(format, msg)
	       end
	       core.log(name, level:upper(), msg)
	    end
      end
   end
   log[name] = domain
   return domain
end

return log
